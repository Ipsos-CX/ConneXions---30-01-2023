
CREATE TABLE [Stage].[Jaguar_France_Sales_VISTA](
	[ID]								INT				IDENTITY (1, 1) NOT NULL,
    [AuditID]							dbo.AuditID		NULL,
    [PhysicalRowID]						INT				NULL,
	
	[Partner Unique Id] 				dbo.LoadText	NULL,
	[Common Order Number] 				dbo.LoadText	NULL,
	[VIN] 								dbo.LoadText	NULL,
	[Customer Id] 						dbo.LoadText	NULL,
	[Cust Type] 						dbo.LoadText	NULL,
	[Payment Type] 						dbo.LoadText	NULL,
	[Common Type of Sale] 				dbo.LoadText	NULL,
	[Handover Date] 					dbo.LoadText	NULL,
	[Salesman Code Dropdown] 			dbo.LoadText	NULL,
	[Contract Relationship] 			dbo.LoadText	NULL,
	[Customers] 						dbo.LoadText	NULL,
	[Surname] 							dbo.LoadText	NULL,
	[Forename(s)] 						dbo.LoadText	NULL,
	[Gender] 							dbo.LoadText	NULL,
	[Academic Title] 					dbo.LoadText	NULL,
	[Date of Birth] 					dbo.LoadText	NULL,
	[Non Academic Title] 				dbo.LoadText	NULL,
	[E-mail Address] 					dbo.LoadText	NULL,
	[Mobile Telephone] 					dbo.LoadText	NULL,
	[Home Telephone] 					dbo.LoadText	NULL,
	[Work Telephone] 					dbo.LoadText	NULL,
	[Address 1] 						dbo.LoadText	NULL,
	[Address 2] 						dbo.LoadText	NULL,
	[Address 3] 						dbo.LoadText	NULL,
	[Address 4] 						dbo.LoadText	NULL,
	[Post Code] 						dbo.LoadText	NULL,
	[Town] 								dbo.LoadText	NULL,
	[Country] 							dbo.LoadText	NULL,
	[Company Name] 						dbo.LoadText	NULL,
	[E-mail marketing opt-in] 			dbo.LoadText	NULL,
	[Telephone Number] 					dbo.LoadText	NULL,
	[Model Description] 				dbo.LoadText	NULL,
	[Model Year Description] 			dbo.LoadText	NULL,
	[Registration Number] 				dbo.LoadText	NULL,
	[Registration Date] 				dbo.LoadText	NULL,
	[Salesman Code] 					dbo.LoadText	NULL,
	[Date of Birth - DAY] 				dbo.LoadText	NULL,
	[Date of Birth - MONTH] 			dbo.LoadText	NULL,
	[Date of Birth - YEAR] 				dbo.LoadText	NULL,
	[Preferred Language] 				dbo.LoadText	NULL,
	[Consent to JLR further contact?]	dbo.LoadText	NULL,
	[Title]								dbo.LoadText	NULL,
	[Flexible Dropdown 1] 				dbo.LoadText	NULL,
	[ConsentToContact]					dbo.LoadText	NULL,
	
	[CombinedDateOfBirth]  				dbo.LoadText	NULL,
	[ConvertedHandoverDate]				DATETIME2		NULL,
	[ConvertedRegistrationDate]			DATETIME2		NULL,
	[ConvertedDateOfBirth]				DATETIME2		NULL,
	
	AdditionalCountry					dbo.LoadText	NULL,
	State								dbo.LoadText	NULL,
	SalesmanFirstName					dbo.LoadText	NULL,
	SalesmanSurname						dbo.LoadText	NULL,
	
	Postal								dbo.LoadText	NULL,			--Bug 15080: France VISTA  sales - new columns to be added to loader
	SMS									dbo.LoadText	NULL,			--Bug 15080: France VISTA  sales - new columns to be added to loader
	Telephone							dbo.LoadText	NULL,			--Bug 15080: France VISTA  sales - new columns to be added to loader
	Email								dbo.LoadText	NULL,			--Bug 15080: France VISTA  sales - new columns to be added to loader
	Digital								dbo.LoadText	NULL,			--Bug 15080: France VISTA  sales - new columns to be added to loader
	PublicationDate						dbo.LoadText	NULL,			--Bug 15080: France VISTA  sales - new columns to be added to loader
	SMSDate								dbo.LoadText	NULL,			--Bug 15080: France VISTA  sales - new columns to be added to loader
	TelephoneDate						dbo.LoadText	NULL,			--Bug 15080: France VISTA  sales - new columns to be added to loader
	EmailDate							dbo.LoadText	NULL,			--Bug 15080: France VISTA  sales - new columns to be added to loader
	[Date num?rique]					dbo.LoadText	NULL			--Bug 15080: France VISTA  sales - new columns to be added to loader
	
	)