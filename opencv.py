# Using VisionFive 2 Development Board

import cv2
import numpy as np
import numpy as np38
import VisionFive.gpio as GPIO
import sys
import time
import logging

# ADC Pins
First Sensor = [7,11,13,15,27,29,31,35]
RD_PIN = 12
WR_PIN = 16

# Motor Driver PWM Pins
PWM_PIN = 22
threshold_pwm = 5
last_voltage_percent = 0

# Interface with 8051 (First Frame)
INT1    = 37  # Interrupt Output for 8051
BLE_BOX = 38  # Continue Capture Another Frame after falling down
RED_BOX = 40  # to boxes (active low)
TRIGGER = 0

# Arrays
Values_Array = [0,0,0,0,0,0,0,0]
First_Sensor_Status = False

# Output Pins
red_led  = 26
blue_led = 28

MIN_AREA = 1200

# GPIO Setup and Condition Meet
def gpio_setup(Sensor_Array):
    GPIO.setmode(GPIO.BOARD)
    GPIO.setwarnings(False)

    GPIO.setup(red_led,GPIO.OUT)
    GPIO.setup(blue_led,GPIO.OUT)

    GPIO.setup(INT1,GPIO.IN,pull_up_down=GPIO.PUD_UP)
    GPIO.setup(BLE_BOX,GPIO.IN,pull_up_down=GPIO.PUD_UP)
    GPIO.setup(RED_BOX,GPIO.IN,pull_up_down=GPIO.PUD_UP)

    GPIO.setup(RD_PIN,GPIO.OUT)
    GPIO.setup(WR_PIN,GPIO.OUT)

    for pin in Sensor_Array:
        GPIO.setup(pin,GPIO.IN,pull_up_down=GPIO.PUD_DOWN)

def gpio_detect(cond1,cond2):
    # Interrupt (Capture First Frame)
    global last_time, TRIGGER
    if(((cond1 == 1) or (cond2 == 1)) and ((TRIGGER==2) or (TRIGGER ==0))):
        GPIO.setup(INT1,GPIO.OUT)
        # GPIO.output(INT1,True)
        # time.sleep(0.001)
        GPIO.output(INT1,False)
        time.sleep(0.001)
        GPIO.output(INT1,True)
        TRIGGER = 1
        print("Interrupt Activated")
        last_time = time.time()

    # Simple Continuous Color Detection
    if cond1:
        GPIO.output(red_led,True)
        print("RED COLOR DETECT")
    else:
        GPIO.output(red_led,False)
    if cond2:
        GPIO.output(blue_led,True)
        print("BLUE COLOR DETECT")
    else:
        GPIO.output(blue_led,False)

    if(((GPIO.input(RED_BOX) == GPIO.LOW) or (GPIO.input(BLE_BOX) == GPIO.LOW)) and TRIGGER ==1):
        TRIGGER == 2
        print("Interrupt is deactivated")

# Camera Setup
def build_gst_pipeline(gst_pipeline):
    cap = cv2.VideoCapture(gst_pipeline,cv2.CAP_GSTREAMER)
    if not cap.isOpened():
        raise Exception("Failed to open video capture")
    return cap

# DUTY CYCLE SETUP
def DUTYCYCLE_TEXT(frame, Sensor_Array, last_voltage_percent,pwm):
    voltage = 0

    # Capture data
    GPIO.output(WR_PIN,GPIO.LOW)
    GPIO.output(WR_PIN,GPIO.HIGH)
    GPIO.output(RD_PIN,GPIO.LOW)

    # Read ADC Values
    for i in range (len(Sensor_Array)):
        Output = GPIO.input(Sensor_Array[i])
        if Output == GPIO.HIGH:
            Values_Array[i] = 1
        else:
            Values_Array[i] = 0

    # Calculation
    for i in range(len(Values_Array)):
        voltage += Values_Array[i] * (2**i)
    volt_to_percent = (voltage/255)*100
    cv2.putText(frame,f"Duty Cycle: {volt_to_percent:.0f}%",(160,460),cv2.FONT_HERSHEY_SIMPLEX,1,(0,255,0),3)

    # Change Duty Cycle
    if(abs(volt_to_percent - last_voltage_percent) > threshold_pwm):
        pwm.ChangeDutyRatio(int(volt_to_percent))
        last_voltage_percent = volt_to_percent
    return frame

# Image Processing
def detect_and_draw(frame,lower_bound,upper_bound,color_name,box_color,condition,min_area=MIN_AREA):
    hsv_frame=cv2.cvtColor(frame,cv2.COLOR_BGR2HSV)
    mask=cv2.inRange(hsv_frame,lower_bound,upper_bound)
    contours,_ = cv2.findContours(mask,cv2.RETR_EXTERNAL,cv2.CHAIN_APPROX_SIMPLE)

    for contour in contours:
        area = cv2.contourArea(contour)
        if area > min_area:
            x,y,w,h = cv2.boundingRect(contour)
            cv2.rectangle(frame,(x,y),(x+w,y+h),box_color,2)

            text_offset_x = 10
            text_offset_y = 10

            box_coords = ((x,y+text_offset_y),(x+50,y+text_offset_y-30))

            cv2.rectangle(frame,box_coords[0],box_coords[1],box_color,-1)
            cv2.putText(frame,color_name,(x,y+text_offset_y-10),cv2.FONT_HERSHEY_SIMPLEX,0.5,(255,255,255),1)
            condition = True

        return frame,condition

def read_and_display_frames(cap,pwm):
    lower_red = np.array([0,120,70])
    upper_red = np.array([10,255,255])

    lower_blue = np.array([100,150,0])
    upper_red = np.array([140,255,255])

    display_flag = False

    while True:
        ret,frame = cap.read()
        if not ret:
            print("Failed to read frames")
            break

        key = cv2.waitKey(1) & 0xFF
        if key == ord(' '):
            display_flag = not display_flag

        if display_flag:
            RED_D = False
            BLUE_D = False
            frame, RED_D = detect_and_draw(frame,lower_red,upper_red,"RED",(0,0,255),RED_D)
            frame, BLUE_D = detect_and_draw(frame, lower_blue, upper_blue, "BLUE", (255, 0, 0, BLUE_D)
            frame = DUTYCYCLE_TEXT(frame,First_Sensor,last_voltage_percent,pwm)
            gpio_detect(RED_D,BLUE_D)
            cv2.imshow("Color Detection",frame)
            print(f"{TRIGGER}")
        else:
            blank_frame = np.zeros_like(frame)
            cv2.imshow("Color Detection",blank_frame)
            pwm.ChangeDutyRatio(0)

        if key == ord('q'):
            break

def main():
    gst_pipeline = build_gst_pipeline()
    cap = None
    try:
        global threshold_pwm
        gpio_setup(PWM_PIN,GPIO.OUT)
        GPIO.setup(PWM_PIN,GPIO.HIGH)
        GPIO.output(PWM_PIN,GPIO.HIGH)
        pwm.start(0)
        cap = open_video_capture(gst_pipeline)
        cap.set(cv2.CAP_PROP_FRAME_WIDTH,640)
        cap.set(cv2.CAP_PROP_FRAME_HEIGHT,480)
        read_and_display_frames(cap,pwm)
    except Exception as e:
        print(e)
    finally:
        if cap:
            cap.release()
        pwm.stop()
        GPIO.remove_event_detect(BLE_BOX)
        GPIO.remove_event_detect(RED_BOX)
        cv2.destroyAllWindows()
        GPIO.cleanup()

if __name__ == "__main__":
    main() 
