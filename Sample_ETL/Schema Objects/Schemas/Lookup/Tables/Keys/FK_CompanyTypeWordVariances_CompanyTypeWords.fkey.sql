ALTER TABLE [Lookup].[CompanyTypeWordVariances]
	ADD CONSTRAINT [FK_CompanyTypeWordVariances_CompanyTypeWords] 
	FOREIGN KEY (CompanyTypeID)
	REFERENCES Lookup.CompanyTypeWords (CompanyTypeID)	

