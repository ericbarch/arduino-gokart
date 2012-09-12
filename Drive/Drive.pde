/* Basic Vehicle Drive System v0.2 by Eric Barch */

#include <SoftwareSerial.h>
#include <Servo.h>

//Define LCD Serial Port
#define rxPin 7
#define txPin 2
SoftwareSerial lcdSerial = SoftwareSerial(rxPin, txPin);

//Pin Defines
#define pwm1 9
#define pwm2 10
#define fwdpotpin 0
#define revpotpin 2
#define steerpotpin 4
#define revpin 13
#define brklight 4

//Speed Controller Objects
Servo leftvictor;
Servo rightvictor;

//Drive variables
int leftdrive = 90;
int rightdrive = 90;
int braking = 0;

//POT Variables
int steerpot = 439;
int fwdpot = 490;
int revpot = 105;
int steerlcd = 50;

//POT Calibration Values
int steerpotmin = 185;
int steerpotmax = 805;
int fwdpotmin = 490;
int fwdpotmax = 731;
int revpotmin = 105;
int revpotmax = 340;

void setup() 
{ 
	leftvictor.attach(pwm1);
	rightvictor.attach(pwm2);

        pinMode(revpin, INPUT);
	pinMode(rxPin, INPUT);
  	pinMode(txPin, OUTPUT);
        pinMode(brklight, OUTPUT);
	lcdSerial.begin(9600);
	backlightOn();
  	
        Serial.begin(9600);
} 

void loop()
{
        steerpot = analogRead(steerpotpin);
        Serial.print("Steer: ");
        Serial.print(steerpot);
        steerpot = map(steerpot, steerpotmin, steerpotmax, 0, 100);
		
        fwdpot = analogRead(fwdpotpin);
	Serial.print(" | Gas: ");
        Serial.print(fwdpot);
	fwdpot = map(fwdpot, fwdpotmin, fwdpotmax, 0, 100);
	
        revpot = analogRead(revpotpin);
        Serial.print(" | Brake: ");
        Serial.print(revpot);
	revpot = map(revpot, revpotmin, revpotmax, 0, 100);

        steerlcd = steerpot;
        
        if (steerpot > 75)
            steerpot = 75;
        else if (steerpot < 25)
            steerpot = 25;
            
        if (steerpot >= 40 && steerpot <= 60)
            steerpot = 50;
        
    	if (fwdpot <= 5 && digitalRead(revpin) == 0)
	{
		leftdrive = 90;
		rightdrive = 90;
	}
	else if (digitalRead(revpin) == 0)
	{
		if (steerpot >= 50) {
                        
			leftdrive = 50 * fwdpot;
			rightdrive = (100 - steerpot) * fwdpot;
		}
		else {
			rightdrive = 50 * fwdpot;
			leftdrive = (0 + steerpot) * fwdpot;
		}
		
                leftdrive = map(leftdrive, 0, 5000, 90, 180);
		rightdrive = map(rightdrive, 0, 5000, 90, 180);
	}
	else if (fwdpot <= 5)
	{
		if (steerpot >= 50) {
			leftdrive = 50 * revpot;
			rightdrive = (100 - steerpot) * revpot;
		}
		else {
			rightdrive = 50 * revpot;
			leftdrive = (0 + steerpot) * revpot;
		}

		leftdrive = map(leftdrive, 0, 5000, 90, 0);
		rightdrive = map(rightdrive, 0, 5000, 90, 0);
	}
        else
        {
                leftdrive = 90;
		rightdrive = 90;
        }

        //Braking
        if (revpot >= 20 && fwdpot <= 20 && digitalRead(revpin) == 0)
        {
                leftdrive = 85;
		rightdrive = 85;
                braking = 1;
                digitalWrite(brklight, HIGH);
        }
        else
        {
                braking = 0;
                digitalWrite(brklight, LOW);
        }

        
	leftvictor.write(leftdrive);
	rightvictor.write(rightdrive);

	Serial.print(" | LDrive: ");
        Serial.print(leftdrive);
        Serial.print(" | RDrive: ");
	Serial.print(rightdrive);
	Serial.print("\n");
        
        outputLCDData();
}

void outputLCDData() {
        leftdrive = map(leftdrive, 0, 180, -100, 100);
	rightdrive = map(rightdrive, 0, 180, -100, 100);

        selectLineOne();
        lcdSerial.print("**** Go Kart v1 ****");
        selectLineTwo();
        lcdSerial.print("Left Drive: ");
        if (braking == 1)
            lcdSerial.print("BRK");
        else {
            lcdSerial.print(leftdrive);
            lcdSerial.print("%   ");
        }
        selectLineThree();
        lcdSerial.print("Right Drive: ");
        if (braking == 1)
            lcdSerial.print("BRK");
        else {
            lcdSerial.print(rightdrive);
            lcdSerial.print("%   ");
        }
        selectLineFour();
        lcdSerial.print("Steering: ");
        lcdSerial.print(steerlcd);
        lcdSerial.print("%   ");
}

void selectLineOne() {
       lcdSerial.print(0xFE, BYTE);   //command flag
       lcdSerial.print(128, BYTE);    //position
}

void selectLineTwo() {
       lcdSerial.print(0xFE, BYTE);   //command flag
       lcdSerial.print(192, BYTE);    //position
}

void selectLineThree() {
       lcdSerial.print(0xFE, BYTE);   //command flag
       lcdSerial.print(148, BYTE);    //position
}

void selectLineFour() {
       lcdSerial.print(0xFE, BYTE);   //command flag
       lcdSerial.print(212, BYTE);    //position
}

void backlightOn(){
        lcdSerial.print(0x7C, BYTE);   //command flag for backlight stuff
        lcdSerial.print(157, BYTE);    //light level.
}

void clearLCD(){
	lcdSerial.print(0xFE, BYTE);   //command flag
	lcdSerial.print(0x01, BYTE);   //clear command.
}
