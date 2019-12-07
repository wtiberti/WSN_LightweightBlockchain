configuration SHA256C {
	provides interface HashFunctionI;
}

implementation {
	components SHA256M;
	HashFunctionI = SHA256M;
}
