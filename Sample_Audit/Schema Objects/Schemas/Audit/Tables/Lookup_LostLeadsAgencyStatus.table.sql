CREATE TABLE [Audit].[Lookup_LostLeadsAgencyStatus]
(
	[AuditItemID]		BIGINT NOT NULL,
	[Market]			NVARCHAR(510) NULL,
	[CICode]			NVARCHAR(20) NULL,
	[Retailer]			NVARCHAR(510) NULL,
	[Brand]				NVARCHAR(510) NULL,
	[LostSalesProvider] NVARCHAR(510) NULL,
	[Confirmation]		NVARCHAR(100) NULL
)