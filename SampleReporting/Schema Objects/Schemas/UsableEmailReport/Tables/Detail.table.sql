CREATE TABLE [UsableEmailReport].[Detail] (
	[ReportDate] [datetime] NOT NULL,
	[DateFrom] [datetime] NOT NULL,
	[DateTo] [datetime] NOT NULL,
	[SubNationalRegion] [nvarchar](255) NULL,
	[CombinedDealer] [nvarchar](255) NULL,
	[DealerName] [nvarchar](150) NULL,
	[DealerCode] [nvarchar](20) NULL,
	[DealerCodeGDD] [nvarchar](20) NULL,
	[FullName] [nvarchar](500) NULL,
	[OrganisationName] [nvarchar](510) NULL,
	[UsableFlag] [int] NULL,
	[PartySuppression] [int] NOT NULL,
	[EmailSuppression] [int] NOT NULL,
	[SuppliedEmail] [int] NOT NULL,
	[UncodedDealer] [int] NOT NULL,
	[InvalidEmailAddress] [int] NOT NULL,
	[BarredEmailAddress] [int] NOT NULL,
	[BarredDomain] [int] NOT NULL,
	[InternalDealer] [int] NOT NULL,
	[EventDateOutOfDate] int NULL,
	[BounceBackFlag] [int] NULL,
	[SampleEmailBounceBackFlag] [int] NULL,
	[OtherReasonsNotSelected]  int NULL,
	[VIN] [nvarchar](50) NULL,
	[RegistrationNumber] NVARCHAR(50) NULL,
	[EventDate] [datetime2](7) NULL,
	[SampleEmailAddress] [dbo].[EmailAddress] NULL,
	[CaseEmailAddress] [dbo].[EmailAddress] NULL,
	MatchedODSEventID  [bigint] NULL,
	AuditItemID [bigint] NOT NULL,
	[GlobalExclusionListMatch] [int] NULL,					-- V1.1
	[PreviousEmailAddress] [dbo].[EmailAddress] NULL,	-- V1.1
	[PreviousEventBounceBack] [int] NULL,				-- V1.1
	[AFRLCode] [nvarchar] (50) NULL,					-- V1.1
	[AFRLCodeUsable] [int] NULL,						-- V1.1
	[RetailerFlag] [int] NULL,								-- V1.1
	[RetailerEmailFlag] [int] NULL,							-- V1.1
	[DealerExclusionListMatch] [int] NULL,					-- V1.1
	[ContactedbyEmail] [int] NULL,					-- V1.1
	[ContactedbyPost] [int] NULL,					-- V1.1
	[InvalidSaleType] [int] NULL				    -- V1.2

) ;