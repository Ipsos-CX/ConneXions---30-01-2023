CREATE TABLE Audit.AFRLCodesLookup (
	AuditItemID	 BIGINT NOT NULL,
	Marque VARCHAR(50) NULL,
	VIN VARCHAR(17) NOT NULL,
	RegistrationDate date,
	RegistrationMark VARCHAR(50) NULL,
	DetailedSalesTypeCode CHAR(1),
	UpdateDate		DATETIME2,
	UpdateType		VARCHAR(20)
)
