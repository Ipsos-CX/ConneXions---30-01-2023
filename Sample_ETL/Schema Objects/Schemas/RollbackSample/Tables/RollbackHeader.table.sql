CREATE TABLE [RollbackSample].[RollbackHeader]
(
	AuditID							dbo.AuditID			NOT NULL,
    RollbackDate					DATETIME2			NOT NULL,
    TotalRows						BIGINT				NOT NULL,
    TotalEvents						BIGINT				NOT NULL,
    TotalCases						BIGINT				NOT NULL,
    TotalContactPrefAdjustments		BIGINT				NULL,
    TotalContactPrefBySurveyAdjustments BIGINT			NULL,
    NonSolicitationsAuditID			BIGINT				NULL,
    ContactPrefAdjustmentsAuditID	BIGINT				NULL,
    UserName						VARCHAR(200)		NOT NULL	
);
