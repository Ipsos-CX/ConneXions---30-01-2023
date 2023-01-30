CREATE TABLE [SampleReport].[SummaryDealerGroup](
	[CombinedDealer] [nvarchar](255) NULL,
	[DealerCode] [nvarchar](20) NULL,
	[DealerCodeGDD] [nvarchar](20) NULL,
	[DealerName] [nvarchar](150) NULL,
	[RecordsLoaded] [int] NULL,
	[SuppliedEmail] [int] NULL,
	[UsableRecords] [int] NULL,
	[InvitesSent] [int] NULL,
	[Bouncebacks] [int] NULL,
	[Responded] [int] NULL,
	[EmailInvites] [int] NULL,
	[SMSInvites] [int] NULL,
	[PostalInvites] [int] NULL,
	[PhoneInvites] [int] NULL,
	[SoftBounce]             [int] NULL,
    [HardBounce]             [int] NULL,
    [Unsubscribes]           [int] NULL,
    [SuppliedPhoneNumber]    [int] NULL,
    [SuppliedMobilePhone]    [int] NULL,
    [PrevSoftBounce]         [int] NULL,
    [PrevHardBounce]         [int] NULL

) ;
