CREATE TABLE Lookup.AFRLCodes (
	Marque VARCHAR(50) NULL,
	VIN VARCHAR(17) NOT NULL,
	RegistrationDate date,
	--MVRISMonth VARCHAR(50) NULL,
	RegistrationMark VARCHAR(50) NULL,
	DetailedSalesTypeCode CHAR(1)
)