#include <Timer.h>
#include "../Message.h"

configuration WSNBlockchainClientC {
}
implementation {
	components MainC;
	components LedsC;
	components WSNBlockchainClientM as App;
	components new TimerMilliC() as Timer0;
	components ActiveMessageC;
	components new AMSenderC(99);
	//components new AMReceiverC(99);
	components SHA256C;
	components RandomC;
	components new PhotoC();
	components LocalTimeMicroC;

	App.Boot -> MainC;
	App.Leds -> LedsC;
	App.Timer0 -> Timer0;
	App.Packet -> AMSenderC;
	App.AMPacket -> AMSenderC;
	App.AMControl -> ActiveMessageC;
	App.AMSend -> AMSenderC;
	//App.Receive -> AMReceiverC;
	App.HashFunctionI -> SHA256C;
	App.Random -> RandomC;
	App.LightSensor -> PhotoC;
	App.LocalTime -> LocalTimeMicroC;

	components SerialPrintfC;
}
