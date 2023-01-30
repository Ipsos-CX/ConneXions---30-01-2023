CREATE TABLE [SampleReport].[SummaryDealerRegionEventsUsable]
(
	[DealerCode] NVARCHAR(20) NULL,
	[DealerCodeGDD] [nvarchar](20) NULL,
	[DealerName] NVARCHAR(150) NULL,
	[SubNationalTerritory] NVARCHAR(255) NULL,
	[SubNationalRegion] NVARCHAR(255) NULL,
	[CombinedDealer] NVARCHAR(255) NULL,
	[EventsReceived] INT NULL,
	[EventDrivenEvents] INT NULL,
	[EventDrivenUsable] INT NULL,
	[EventDrivenInvites] INT NULL,
	[EventDrivenResponses] INT NULL,
	[EventDrivenOutOfDate] INT NULL, 
	[EventDrivenPartyNonSolicitation] INT NULL,
	[EventDrivenNonLatestEvent] INT NULL,
	[EventDrivenUncodedDealer] INT NULL,
	[EventDrivenEventAlreadySelected] INT NULL,
	[EventDrivenWithinRecontactPeriod] INT NULL,
	[EventDrivenWithinRelativeRecontactPeriod] INT NULL,
	[EventDrivenExclusionListMatch] INT NULL,


	[EventDrivenEmailInvites] INT NULL,
	[EventDrivenSMSInvites] INT NULL,
	[EventDrivenPostalInvites] INT NULL,
	[EventDrivenPhoneInvites] INT NULL,
	[EventDrivenBarredEmailAddress] INT NULL,
	[EventDrivenBarredDomain] INT NULL,
	[EventDrivenInvalidEmailAddress] INT NULL,
	[EventDrivenMissingMobilePhone] INT NULL,
	[EventDrivenMissingMobilePhoneAndEmail] INT NULL,
	
	[EventDrivenManualRejectionFlag] INT NULL,
	[EventDrivenOther] INT NULL,
	[DDWDrivenEvents] INT NULL,
	[DDWDrivenInvites] INT NULL,
	[DDWDrivenResponses] INT NULL,

	[DDWDrivenEmailInvites] INT NULL,
	[DDWDrivenSMSInvites] INT NULL,
	[DDWDrivenPostalInvites] INT NULL,
	[DDWDrivenPhoneInvites] INT NULL,
	
	[EventDrivenUnmatchedModel] INT NULL,
	[EventDrivenWrongEventType] INT NULL,
	[EventDrivenEventNonSolicitation] INT NULL,
	[EventDrivenPartySuppression] INT NULL,
	[EventDrivenPostalSuppression] INT NULL,
	[EventDrivenEmailSuppression] INT NULL,
	[EventDrivenBouncebackFlag] INT NULL,
	[EventDrivenMissingStreetAndEmail] INT NULL,
	[EventDrivenMissingLanguage] INT NULL,
	[EventDrivenInvalidManufacturer] INT NULL,
	[EventDrivenInternalDealer] INT NULL,	
	[EventDrivenMissingPartyName] INT NULL,
	[EventDrivenInvalidOwnershipCycle] INT NULL,
	

	[EventDrivenMissingStreet] INT NULL,
	[EventDrivenMissingPostcode] INT NULL,
	[EventDrivenMissingEmail] INT NULL,
	[EventDrivenMissingTelephone] INT NULL,
	[EventDrivenMissingTelephoneAndEmail] INT NULL,
	
	[EventDrivenPreviousEventBounceBack]	INT NULL,
	[EventDrivenEventDateTooYoung] INT NULL,
	
	[EventDrivenSuppliedName] INT NULL,
	[EventDrivenSuppliedAddress] INT NULL,
	[EventDrivenSuppliedPhoneNumber] INT NULL,	
	[EventDrivenSuppliedMobilePhone] INT NULL,

	[EventDrivenDealerExclusionListMatch] [int] NULL,
	[EventDrivenPhoneSuppression] [int] NULL,
	[EventDrivenInvalidAFRLCode] [int] NULL,
	[EventDrivenInvalidSalesType] [int] NULL,
	
	[EventDrivenPrevSoftBounce] [int] NULL,
    [EventDrivenPrevHardBounce] [int] NULL,
    [EventDrivenHardBounce] [int] NULL,
    [EventDrivenSoftBounce] [int] NULL,
    [EventDrivenUnsubscribes] [int] NULL,
    
    [EventDrivenSVCRMInvalidSalesType] [int] NULL,
    
    [EventDrivenContactPreferencesSuppression] int NULL,		-- 07-09-2017 - BUG 13364
    [EventDrivenContactPreferencesPartySuppress] int NULL,		-- 07-09-2017 - BUG 13364
    [EventDrivenContactPreferencesEmailSuppress] int NULL,		-- 07-09-2017 - BUG 13364
    [EventDrivenContactPreferencesPhoneSuppress] int NULL,		-- 07-09-2017 - BUG 13364
    [EventDrivenContactPreferencesPostalSuppress] int NULL,		-- 07-09-2017 - BUG 13364
    [EventDrivenPDIFlagSet]		int NULL,						-- 07-09-2017 - BUG 14122
    
    [EventDrivenOriginalPartySuppression] INT NULL,						 -- BUG 14379
	[EventDrivenOriginalPostalSuppression] INT NULL,					 -- BUG 14379	
	[EventDrivenOriginalEmailSuppression] INT NULL,						 -- BUG 14379	
	[EventDrivenOriginalPhoneSuppression] INT NULL,						 -- BUG 14379 
	[EventDrivenOtherExclusion] INT NULL,								 -- BUG 14487	
	[EventDrivenSuppliedEmail] INT NULL,							     -- BUG 15211
	[EventDrivenInvalidDateOfLastContact] INT NULL                       -- BUG 15216

);

