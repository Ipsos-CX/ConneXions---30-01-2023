ALTER TABLE [Lookup].[LostLeadsAgencyStatus]
	ADD CONSTRAINT [PK_LostLeadsAgencyStatus] 
	PRIMARY KEY CLUSTERED ([Market] ASC, [CICode] ASC, [Retailer] ASC) 