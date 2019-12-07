#include <Timer.h>
#include "../Message.h"

configuration WSNBlockchainC {
}
implementation {
	components MainC;
	components LedsC;
	components WSNBlockchainM as App;
	components ActiveMessageC;
	components new AMReceiverC(99);
	components SHA256C;
	components LocalTimeMicroC;
	components LedgerC;

	App.Boot -> MainC;
	App.Leds -> LedsC;
	App.AMControl -> ActiveMessageC;
	App.Receive -> AMReceiverC;
	App.HashFunctionI -> SHA256C;
	App.LocalTime -> LocalTimeMicroC;
	App.LedgerI -> LedgerC;

	components SerialPrintfC;
}
