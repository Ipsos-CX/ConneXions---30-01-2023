CREATE TABLE [UsableEmailReport].[Base] (
	[ReportDate] [datetime] NOT NULL,
	[DateFrom] [datetime] NOT NULL,
	[DateTo] [datetime] NOT NULL,
	[SuperNationalRegion] [nvarchar](250) NULL,
	[BusinessRegion] [nvarchar](250) NULL,
	[DealerMarket] [nvarchar](255) NULL,
	[SubNationalRegion] [nvarchar](255) NULL,
	[CombinedDealer] [nvarchar](255) NULL,
	[DealerName] [nvarchar](150) NULL,
	[DealerCode] [nvarchar](20) NULL,
	[DealerCodeGDD] [nvarchar](20) NULL,
	[FullName] [nvarchar](500) NULL,
	[OrganisationName] [nvarchar](510) NULL,
	[DuplicateRowFlag] [int] NULL,
	[UsableFlag] [int] NULL,
	[FileName] [varchar](100) NULL,
	[FileActionDate] [datetime] NULL,
	[FileRowCount] [int] NULL,
	[LoadedDate] [datetime2](7) NOT NULL,
	[AuditID] [bigint] NOT NULL,
	[AuditItemID] [bigint] NOT NULL,
	[MatchedODSPartyID] [bigint] NOT NULL,
	[MatchedODSPersonID] [bigint] NOT NULL,
	[PartySuppression] [bigint] NOT NULL,
	[MatchedODSOrganisationID] [bigint] NOT NULL,
	[EmailSuppression] [int] NOT NULL,
	[MatchedODSVehicleID] [bigint] NOT NULL,
	[ODSRegistrationID] [bigint] NULL,
	[MatchedODSEventID] [bigint] NOT NULL,
	[ODSEventTypeID] [int] NULL,
	[Brand] [nvarchar](510) NULL,
	[Market] [varchar](200) NULL,
	[SuppliedEmail] [int] NOT NULL,
	[UncodedDealer] [int] NOT NULL,
	[ExclusionListMatch] [int] NOT NULL,
	[InvalidEmailAddress] [int] NOT NULL,
	[BarredEmailAddress] [int] NOT NULL,
	[BarredDomain] [int] NOT NULL,
	[InternalDealer] [int] NOT NULL,
	[EventDateOutOfDate] [int] NOT NULL,
	[BounceBackFlag] [int] NOT NULL,
	[SampleEmailBounceBackFlag] [int] NOT NULL,
	[OtherReasonsNotSelected]  int NULL,
	[RegistrationNumber] [nvarchar](100) NULL,
	[RegistrationDate] [datetime2](7) NULL,
	[VIN] [nvarchar](50) NULL,
	[EventDate] [datetime2](7) NULL,
	[CaseID] bigint NULL,
	[MatchedODSEmailAddressID] [int] NULL,
	[SampleEmailAddress] [dbo].[EmailAddress] NULL,
	[CaseEmailAddress] [dbo].[EmailAddress] NULL,
	[PreviousEmailAddress] [dbo].[EmailAddress] NULL,	-- V1.1
	[PreviousEventBounceBack] [int] NULL,				-- V1.1
	[AFRLCode] [nvarchar](50) NULL,						-- V1.1
	[AFRLCodeUsable] [int] NULL,						-- V1.1
	[RetailerFlag] [int] NULL,								-- V1.1
	[RetailerEmailFlag] [int] NULL,							-- V1.1
	[DealerExclusionListMatch] [int] NULL,					-- V1.1
	[ContactedbyEmail] [int] NULL,					-- V1.1
	[ContactedbyPost] [int] NULL,					-- V1.1
	[InvalidSaleType] [int] NULL				    -- V1.2
) ;

