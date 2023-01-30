CREATE TABLE [Stage].[LostLeadsAgencyStatus]
(
	[ID] [int]								IDENTITY(1,1) NOT NULL,
	[AuditID] [bigint]						NULL,
	[AuditItemID] [bigint]					NULL,
	[ParentAuditItemID] [bigint]			NULL,
	[Market] [nvarchar](2000)				NULL,
	[CICode] [nvarchar](2000)				NULL,
	[Retailer] [nvarchar](2000)				NULL,
	[Brand] [nvarchar](2000)				NULL,
	[LostSalesProvider] [nvarchar](2000)	NULL,
	[ConfirmationYN] [nvarchar](2000)		NULL
)
