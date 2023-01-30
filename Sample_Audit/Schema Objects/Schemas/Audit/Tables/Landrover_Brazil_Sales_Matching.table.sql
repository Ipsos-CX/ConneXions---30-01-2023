CREATE TABLE [Audit].[Landrover_Brazil_Sales_Matching] 
(
	[CustomerAuditID]		bigint NOT NULL,
	[CustomerAuditItemID]	bigint NOT NULL,
	[ContractAuditID]		bigint NOT NULL,
	[ContractAuditItemID]	bigint NOT NULL)
ON [PRIMARY];
GO