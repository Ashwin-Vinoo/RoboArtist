#include<LiquidCrystal.h>
LiquidCrystal lcd(44,45,46,47,48,49);
int i=0,j,k=0,ex_byte,flag;
float posl[3],posh[3];
long totalcount,measure=0;
int speed_servo[3]={
  100,130,160};
byte up_arrow[8]={
  0b00100,0b01110,0b10101,0b00100,0b00100,0b00100,0b00100,0b00100};
byte down_arrow[8]={
  0b00100,0b00100,0b00100,0b00100,0b00100,0b10101,0b01110,0b00100};
void setup()
{ 
  lcd.createChar(1,up_arrow);
  lcd.createChar(2,down_arrow);
  lcd.begin(20,4);
  pinMode(2,OUTPUT);
  pinMode(3,OUTPUT);
  pinMode(4,OUTPUT);
  pinMode(5,OUTPUT);
  pinMode(6,OUTPUT); 
  pinMode(13,OUTPUT); 
  digitalWrite(2,HIGH);
  digitalWrite(3,HIGH);
  analogWrite(4,255);
  analogWrite(5,255);
  analogWrite(6,255);
  Serial.begin(9600);
  Serial1.begin(9600);
  Serial2.begin(1000000);
  Serial.flush();
  Serial1.flush();
  Serial2.flush();
  lcd.setCursor(5,0);
  lcd.print("ROBOARTIST");
  lcd.setCursor(0,1);
  lcd.print("Created by:  Niaz");
  lcd.setCursor(0,2);
  lcd.print("Arjun S, Abhijith SJ");
  lcd.setCursor(0,3);
  lcd.print("Ashwin Vinoo, Athul");
  delay(3000);
  lcd.clear();
  lcd.setCursor(0,1);
  lcd.print("Please initiate your");
  lcd.setCursor(3,2);
  lcd.print("Matlab code...");
restart:
  while(!Serial.available()&&!Serial1.available())
  {    
  }
  if(Serial.available())
  {
    if(Serial.read()!=50)
      goto restart;
    flag=0;
    Serial1.end();
  }
  else
  {
    if(Serial1.read()!=50)
      goto restart;
    flag=1;
    Serial.end();
  }
  lcd.clear();
  lcd.setCursor(2,1);
  lcd.print("Your Matlab code");
  lcd.setCursor(3,2);
  lcd.print("is executing...");
  AX_MOVE_SPEED(4,2,70,120); 
  delay(250);
  while(i==0)
  {
    for(j=0;j<=255;j++)
    {
      if(k==0)
        analogWrite(6,255-j);
      else
        analogWrite(6,j);
      delay(10);
      if(flag==0)
      {
        if(Serial.available())
        {
          i=1;
          break;
        }
      } 
      else
      {
        if(Serial1.available())
        {
          i=1;
          break;
        }        
      }
    }
    k=!k;
  }
  analogWrite(6,255);
  if(flag==0)
    s_call();
  else
    s1_call();
  totalcount=posl[0]+posl[1]*256+posl[2]*65536;
  i=0;
  k=0;
}
void loop() 
{
  while(i<=7)
  {
    if(flag==0)
      s_call();
    else
      s1_call();
    posh[0]=(bitRead(ex_byte,7)*2+bitRead(ex_byte,6));
    posh[1]=(bitRead(ex_byte,5)*2+bitRead(ex_byte,4));
    posh[2]=(bitRead(ex_byte,3)*2+bitRead(ex_byte,2));
    lcd.clear();
    lcd.setCursor(0,0);
    lcd.print("Servo1 angle:");
    lcd.print((posh[0]*256+posl[0])*300/1023-150);
    lcd.setCursor(0,1);
    lcd.print("Servo2 angle:");
    lcd.print((posh[1]*256+posl[1])*300/1023-150);
    lcd.setCursor(0,2);
    lcd.print("Servo3 angle:");
    lcd.print((posh[2]*256+posl[2])*300/1023-150);
    AX_MOVE_SPEED(1,posh[0],posl[0],speed_servo[0]); 
    AX_MOVE_SPEED(2,posh[1],posl[1],speed_servo[1]); 
    AX_MOVE_SPEED(3,posh[2],posl[2],speed_servo[2]); 
    if(bitRead(ex_byte,0)==0)
    {
      k=1;
      AX_MOVE_SPEED(4,2,53,120);
    }
    if(k==0)
    {
      lcd.setCursor(0,3);
      lcd.print("Servo4 angle:  up  ");
      lcd.write(1); 
      if(bitRead(ex_byte,0)==1)  
      {
        if(bitRead(ex_byte,1)==1)
        {
          delay(1000);
        } 
        delay(750);
        AX_MOVE_SPEED(4,2,50,120);
        delay(250);
        k=1;
      }
    }
    else
    {
      lcd.setCursor(0,3);
      lcd.print("Servo4 angle: down ");
      lcd.write(2);
      if(bitRead(ex_byte,0)==1)  
      {
        delay(250);
        AX_MOVE_SPEED(4,2,70,120);
        delay(250);
        k=0;
      } 
    }
    delay(9);
    i++; 
    measure++;
    if(measure==totalcount)
    {
      lcd.clear();
      lcd.setCursor(0,0);
      lcd.print("YOUR IMAGE HAS BEEN");
      lcd.setCursor(0,1);
      lcd.print("SUCCESSFULLY DRAWN.");
      lcd.setCursor(2,2);
      lcd.print("PLEASE REMOVE THE");
      lcd.setCursor(0,3);
      lcd.print("MOUNTED SKETCH SHEET");
      digitalWrite(13,HIGH);
      delay(250);      
      digitalWrite(13,LOW);
      delay(250);
      digitalWrite(13,HIGH);
      delay(250);      
      digitalWrite(13,LOW);
      AX_MOVE_SPEED(1,1,54,speed_servo[0]); 
      AX_MOVE_SPEED(2,2,0,speed_servo[1]); 
      AX_MOVE_SPEED(3,3,50,speed_servo[2]);
      while(1)
      {   
      }
    }
  }
  j=255*(float(measure)/float(totalcount));
  analogWrite(4,j);
  analogWrite(5,255-j);
  if(flag==0)
    Serial.write(50);
  else
    Serial1.write(50);
  i=0;  
}
//**************************************************************************FUNCTION DECLARATION STARTS HERE***********************************************************************
void s_call()
{
  while(!Serial.available())
  {
  }
  posl[0]=Serial.read();
  while(!Serial.available())
  {
  }
  posl[1]=Serial.read();
  while(!Serial.available())
  {
  }
  posl[2]=Serial.read();
  while(!Serial.available())
  {
  }
  ex_byte=Serial.read();
}
void s1_call()
{
  while(!Serial1.available())
  {
  }
  posl[0]=Serial1.read();
  while(!Serial1.available())
  {
  }
  posl[1]=Serial1.read();
  while(!Serial1.available())
  {
  }
  posl[2]=Serial1.read();
  while(!Serial1.available())
  {
  }
  ex_byte=Serial1.read();
}
void AX_MOVE(unsigned char ID,char Position_H,char Position_L)
{  
  unsigned char AX_ID=ID;     // BROADCAST ID
  unsigned char AX_CHECKSUM;   // CHECKSUM VALUE
  int AX_LENGTH=5;             // LENGTH OF INSTRUCTION N+2
  int AX_INSTRUCTION=3;        // TYPE OF INSTRUCTION FOR WRITING DATA (0X03)
  int AX_POSITION_LOCATION=30;        // STARTING LOCATION OF PARAMETER IN CONTROL TABLE
  char AX_PARAMETER_1=Position_L;        // NEW PARAMETER VALUE
  char AX_PARAMETER_2=Position_H;        // NEW PARAMETER VALUE
  AX_CHECKSUM = (~(AX_ID + AX_LENGTH + AX_INSTRUCTION + AX_POSITION_LOCATION + AX_PARAMETER_1 + AX_PARAMETER_2))&0xFF; // CHECKSUM CALCULATION
  Serial2.write(255);                 // AX12 INSTRUCTIONS OVER SERAL
  Serial2.write(255);
  Serial2.write(AX_ID);
  Serial2.write(AX_LENGTH);
  Serial2.write(AX_INSTRUCTION);
  Serial2.write(AX_POSITION_LOCATION);
  Serial2.write(AX_PARAMETER_1);
  Serial2.write(AX_PARAMETER_2);
  Serial2.write(AX_CHECKSUM);
} 
void AX_MOVE_SPEED(unsigned char ID,char Position_H,char Position_L,int speed)
{  
  digitalWrite(2,HIGH);
  int Speed_L,Speed_H;
  Speed_L=speed & 255;
  Speed_H=speed>>8;    
  unsigned char AX_ID=ID;     // BROADCAST ID
  unsigned char AX_CHECKSUM;   // CHECKSUM VALUE
  int AX_LENGTH=7;             // LENGTH OF INSTRUCTION N+2
  int AX_INSTRUCTION=3;        // TYPE OF INSTRUCTION FOR WRITING DATA (0X03)
  int AX_POSITION_LOCATION=30;        // STARTING LOCATION OF PARAMETER IN CONTROL TABLE
  unsigned char AX_PARAMETER_1=Position_L;        // NEW PARAMETER VALUE
  unsigned char AX_PARAMETER_2=Position_H;        // NEW PARAMETER VALUE
  unsigned char AX_PARAMETER_3=Speed_L;        // NEW PARAMETER VALUE
  unsigned char AX_PARAMETER_4=Speed_H;        // NEW PARAMETER VALUE  
  AX_CHECKSUM = (~(AX_ID + AX_LENGTH + AX_INSTRUCTION + AX_POSITION_LOCATION + AX_PARAMETER_1 + AX_PARAMETER_2 + AX_PARAMETER_3 + AX_PARAMETER_4))&0xFF; // CHECKSUM CALCULATION    
  Serial2.write(255);                 // AX12 INSTRUCTIONS OVER SERAL
  Serial2.write(255);
  Serial2.write(AX_ID);
  Serial2.write(AX_LENGTH);
  Serial2.write(AX_INSTRUCTION);
  Serial2.write(AX_POSITION_LOCATION);
  Serial2.write(AX_PARAMETER_1);
  Serial2.write(AX_PARAMETER_2);
  Serial2.write(AX_PARAMETER_3);
  Serial2.write(AX_PARAMETER_4);
  Serial2.write(AX_CHECKSUM);
  digitalWrite(2,LOW);
} 
void AX_ID_INITIALIZE(unsigned char AX_ID,unsigned char AX_PARAMETER_1)
{
  unsigned char AX_CHECKSUM;   // CHECKSUM VALUE
  int AX_LENGTH=4;             // LENGTH OF INSTRUCTION N+2
  int AX_INSTRUCTION=3;        // TYPE OF INSTRUCTION FOR WRITING DATA (0X03)
  int AX_ID_LOCATION=3;        // STARTING LOCATION OF PARAMETER IN CONTROL TABLE     
  AX_CHECKSUM = (~(AX_ID + AX_LENGTH + AX_INSTRUCTION + AX_ID_LOCATION + AX_PARAMETER_1))&0xFF; // CHECKSUM CALCULATION
  Serial2.write(255);                 // AX12 INSTRUCTIONS OVER SERAL
  Serial2.write(255);
  Serial2.write(AX_ID);
  Serial2.write(AX_LENGTH);
  Serial2.write(AX_INSTRUCTION);
  Serial2.write(AX_ID_LOCATION);
  Serial2.write(AX_PARAMETER_1);
  Serial2.write(AX_CHECKSUM);
}
/*void AX_MOVE_SYNC(int ids[],int posl[],int posh[],int sped[])
 {  
 int speedl,speedh,i=0;
 tx_packet[0]=0xff;
 tx_packet[1]=0xff;
 tx_packet[2]=0xfe;
 tx_packet[3]=0x13;
 tx_packet[4]=0x83;
 tx_packet[5]=0x1e;
 tx_packet[6]=0x04;
 for(i=0;i<3;i++)
 {
 tx_packet[7+i*5]=ids[i];
 tx_packet[8+i*5]=posl[i];
 tx_packet[9+i*5]=posh[i];
 speedl=sped[i]&255;
 speedh=sped[i]>>8;
 tx_packet[10+i*5]=speedl;
 tx_packet[11+i*5]=speedh;
 }
 tx_packet[7+i*5]=checksum();
 for(i = 0;i<tx_packet[3]+4;i++)
 Serial.write(tx_packet[i]);
 }*/

















