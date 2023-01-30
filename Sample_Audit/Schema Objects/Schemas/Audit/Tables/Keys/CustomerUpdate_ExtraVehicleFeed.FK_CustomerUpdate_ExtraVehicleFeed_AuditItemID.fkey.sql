ALTER TABLE [Audit].[CustomerUpdate_ExtraVehicleFeed]
	ADD CONSTRAINT [FK_CustomerUpdate_ExtraVehicleFeed_AuditItems] 
	FOREIGN KEY (AuditItemID)
	REFERENCES dbo.AuditItems (AuditItemID)	

