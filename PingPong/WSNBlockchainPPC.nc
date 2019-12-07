#include <Timer.h>
#include "../Message.h"

configuration WSNBlockchainPPC {
}
implementation {
	components MainC;
	components LedsC;
	components WSNBlockchainPPM as App;
	components ActiveMessageC;
	components new AMReceiverC(99);
	components new AMSenderC(99);
	components RandomC;
	components new PhotoC();
	components SHA256C;
	components LocalTimeMicroC;
	components LedgerC;

	App.Boot -> MainC;
	App.Leds -> LedsC;
	App.AMControl -> ActiveMessageC;
	App.Receive -> AMReceiverC;
	App.HashFunctionI -> SHA256C;
	App.LocalTime -> LocalTimeMicroC;
	App.AMSend -> AMSenderC;
	App.Packet -> AMSenderC;
	App.AMPacket -> AMSenderC;
	App.Random -> RandomC;
	App.LightSensor -> PhotoC;
	App.LedgerI -> LedgerC;

	components SerialPrintfC;
}
