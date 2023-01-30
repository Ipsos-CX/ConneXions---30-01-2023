CREATE TABLE [Merge].[SampleQualityAndSelectionLogging]
(
	[MergeAuditItemID]              dbo.AuditItemID			NOT NULL,		-- The AuditItemID linked to Merge file
	[MergeAuditRowType]				dbo.MergeAuditRowType	NOT NULL,		-- The type of values in the row e.g. BEFORE or AFTER merge/un-merge
	
    [LoadedDate]                         DATETIME2 (7)              NOT NULL,
    [AuditID]                            [dbo].[AuditID]            NOT NULL,
    [AuditItemID]                        [dbo].[AuditItemID]        NOT NULL,
    [PhysicalFileRow]                    INT                        NOT NULL,
    [MatchedODSPartyID]                  [dbo].[PartyID]            NOT NULL,
    [MatchedODSPersonID]                 [dbo].[PartyID]            NOT NULL,
    [MatchedODSOrganisationID]           [dbo].[PartyID]            NOT NULL,
)
