#include <Adafruit_MCP4725.h>
#include <Servo.h>

Servo panelServo;
Adafruit_MCP4725 dac;

enum devices
{
  FLAT_MAN_L = 10,
  FLAT_MAN_XL = 15,
  FLAT_MAN = 19,
  FLIP_FLAT = 99
};

enum motorStates
{
  MS_STOPPED = 0,
  MS_RUNNING
};

enum lightStates
{
  LS_OFF = 0,
  LS_ON
};

enum coverStates
{
  CS_UNKNOWN = 0,
  CS_CLOSED,
  CS_OPEN,
  CS_TIMEOUT
};


// To be adapted
const unsigned long MOVING_TIME = 2500L;    // motor moving time (for open or close) in ms

const int SERVOPOS_CLOSE = 3;               // servo position for closed cover
const int SERVOPOS_OPEN = 158;              // servo position for open cover

const int SLOW_LOW = 30;                    // low border for slow movement
const int SLOW_HIGH = 130;                  // high border for slow movement
const int SLOW_CYCLE = 40;                  // cycle time for slow movement increment (ms)
const int FAST_CYCLE = 20;                  // cycle time for fast movement increment (ms)

const int FIRMWARE_VERSION = 3;             // firmware version

const int SERVO_PIN = 8;                    // Servo pin for PWM signal


// No adaptations necessary
//unsigned long movingEndTime = 0;            // timestamp until motor moving is reported
const int ARG_OOO = 1000;                   // reply with argument OOO

int charIdx = 0;  // index of last received character in message buffer
int argVal;       // value of received message argument
char currCmd;     // current command character of received message
unsigned long nextCheck = 0;   // timestamp for next servo movement check

motorStates currMotorState = MS_STOPPED;    // current motor state
lightStates currLightState = LS_OFF;        // current light state
coverStates currCoverState = CS_OPEN;       // current cover state
unsigned int currBrightness = 128;          // current set brightness (0..255, might be overruled by light state)
int targetServoPos = SERVOPOS_CLOSE;        // target servo position

// Set DAC value for panel brightness
void SetDAC(unsigned int val) {
  dac.setVoltage((uint16_t)(val * 16), false); // convert to 12 bit value
}


void HandleServo() {
  int currServoPos;

  if (millis() >= nextCheck) {   // time for next movement?
    currServoPos = panelServo.read();
    if (currServoPos != targetServoPos) {   // adjust to target position by 1
      if (currServoPos < targetServoPos) {
        currServoPos += 1;
      }
      else {
        currServoPos -= 1;
      }
    }
    panelServo.write(currServoPos);  // move servo
    if ((currServoPos < SLOW_LOW) || (currServoPos > SLOW_HIGH)) {   // calculate time for next movement
      nextCheck = millis() + SLOW_CYCLE;
    }
    else {
      nextCheck = millis() + FAST_CYCLE;
    }
  }
}


// Send reply, cmd=command character, arg=argument value or >10000 for OOO (NOT 000!)
void Reply(char cmd, int arg) {
  char msgBuf[9];

  msgBuf[0] = '*';
  msgBuf[1] = cmd;
  msgBuf[2] = '9';   // Flip-flat device
  msgBuf[3] = '9';
  if (arg < ARG_OOO) {    // argument is a value 0..999
    int a1 = arg % 10;
    arg = (arg - a1) / 10;
    int a10 = arg % 10;
    arg = (arg - a10) / 10;
    msgBuf[4] = (char)arg + '0';
    msgBuf[5] = (char)a10 + '0';
    msgBuf[6] = (char)a1 + '0';
  }
  else {  // argument is OOO (NOT 000!)
    msgBuf[4] = 'O';
    msgBuf[5] = 'O';
    msgBuf[6] = 'O';

  }
  msgBuf[7] = (char)0x0A;
  msgBuf[8] = 0;
  Serial.print(msgBuf);
}

// Ping
void CmdPing() {
  Reply('P', ARG_OOO);
}

// Open cover
void CmdOpen() {
  currCoverState = CS_OPEN;
  targetServoPos = SERVOPOS_OPEN;
  nextCheck = millis() + SLOW_CYCLE;
  Reply('O', ARG_OOO);
}

// Close cover
void CmdClose() {
  currCoverState = CS_CLOSED;
  targetServoPos = SERVOPOS_CLOSE;
  nextCheck = millis() + SLOW_CYCLE;
  Reply('C', ARG_OOO);
}

// Switch light on (with set brightness)
void CmdLightOn() {
  currLightState = LS_ON;
  SetDAC(currBrightness);
  Reply('L', ARG_OOO);
}

// Switch light off (but preserve brightness)
void CmdLightOff() {
  currLightState = LS_OFF;
  SetDAC(0);
  Reply('D', ARG_OOO);
}

// Set brightness
void CmdSetBrightness(int val) {
  currBrightness = val;
  if (currLightState == LS_ON) {
    SetDAC(currBrightness);
  }
  Reply('B', val);
}

// Set servo position (this is an additional command, not covered by the default protocol)
void CmdServoPos(int val) {
  panelServo.write(val);
  Reply('Z', val);
}

// Get current brightness
void CmdGetBrightness() {
  Reply('J', currBrightness);
}

// Get state
void CmdGetState() {
  int st;

  if (panelServo.read() == targetServoPos) { // not moving, report no movement and cover state
    st = (100 * currMotorState) + (10 * currLightState) + currCoverState;
  } else { // moving, report movement and unknown cover stte
    st = (100 * MS_RUNNING) + (10 * currLightState) + CS_UNKNOWN;
  }
  Reply('S', st);
}

// Get firmware version
void CmdGetVersion() {
  Reply('V', FIRMWARE_VERSION);
}

// poll UART and process received characters
void CheckUART() {
  if (Serial.available() > 0) {
    char inChar = Serial.read();

    switch (charIdx) {
      case 0:   // first char
        if (inChar == '>') {
          charIdx++;
          argVal = 0;  // clear argument value
        }
        break;
      case 1:   // 2nd char = command
        switch (inChar) {
          // supported command characters
          case 'P':
          case 'O':
          case 'C':
          case 'L':
          case 'D':
          case 'B':
          case 'J':
          case 'S':
          case 'V':
          case 'Z':
            currCmd = inChar;
            charIdx++;
            break;
          default:  // unknown command, discard all
            charIdx = 0;
            break;
        }
        break;
      case 2:   // 3.-5. char = arg
      case 3:   // 3.-5. char = arg
      case 4:   // 3.-5. char = arg
        if ((currCmd != 'B') && (currCmd != 'Z')) {  // the only commands with numerical arguments
          // no numerical argument expected
          if ((inChar == '0') || (inChar == 'O')) {
            charIdx++;
          }
          else {
            charIdx = 0;
          }
        }
        else {
          // numerical argument expected
          if (inChar == 'O') {
            inChar = '0';
          }
          if ((inChar >= '0') && (inChar <= '9')) {
            argVal = (10 * argVal) + (inChar - '0');
            charIdx++;
          }
          else {
            charIdx = 0;
          }
        }
        break;
      case 5:   // 6. char = CR
        charIdx = 0;
        if ((inChar == '\n') || (inChar == 0x0d)) {
          switch (currCmd) {
            case 'P':
              CmdPing();
              break;
            case 'O':
              CmdOpen();
              break;
            case 'C':
              CmdClose();
              break;
            case 'L':
              CmdLightOn();
              break;
            case 'D':
              CmdLightOff();
              break;
            case 'B':
              CmdSetBrightness(argVal);
              break;
            case 'J':
              CmdGetBrightness();
              break;
            case 'S':
              CmdGetState();
              break;
            case 'V':
              CmdGetVersion();
              break;
            case 'Z':
              CmdServoPos(argVal);
              break;

          }
          break;
        }
        break;
    }
  }
}


void setup() {
  dac.begin(0x60);                   // Address for MCP4725A0
  panelServo.attach(SERVO_PIN);
  SetDAC(0);                         // start with light off
  currCoverState = CS_CLOSED;
  panelServo.write(SERVOPOS_CLOSE);  // start with closed cover
  Serial.begin(9600);
}


void loop() {
  CheckUART();   // poll UART
  HandleServo();
}
