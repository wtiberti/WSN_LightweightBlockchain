configuration LedgerC {
	provides interface LedgerI;
}

implementation {
	components SHA256C;
	components LedgerM;

	LedgerM.HashFunctionI -> SHA256C;
	LedgerI = LedgerM.LedgerI;
}
