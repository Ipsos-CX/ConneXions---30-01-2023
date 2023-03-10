
CREATE TABLE [dbo].[ServiceDispositionReport](
	[ServiceDealerCode] [nvarchar](255) NULL,
	[DealerName] [nvarchar](255) NULL,
	[DealerRegion] [nvarchar](255) NULL,
	[Brand] [nvarchar](255) NULL,
	[Market] [nvarchar](255) NULL,
	[Questionnaire] [nvarchar](255) NULL,
	[AllDealerCount] [int] null,
	[SampleLoadedFromFile] [int] NULL,
	[ValidSampleFromFile] [int] NULL,
	[ValidSampleThisPeriod] [int] NULL,
	[CaseOutputType_CATI] [int] NULL,
	[CaseOutputType_Online] [int] NULL,
	[CaseOutputType_Postal] [int] NULL,
	[CaseOutputType_NonOutput] [int] NULL,
	[SumOFSuppliedName] [int] NULL,
	[SumOFSuppliedAddress] [int] NULL,
	[SumOFSuppliedPhoneNumber] [int] NULL,
	[SumOFSuppliedEmail] [int] NULL,
	[SumOFSuppliedVehicle] [int] NULL,
	[SumOFSuppliedRegistration] [int] NULL,
	[SumSuppliedEventDate] [int] NULL,
	[SumEventDateOutOfDate] [int] NULL,
	[SumEventNonSolicitation] [int] NULL,
	[SumPartyNonSolicitation] [int] NULL,
	[SumUnmatchedModel] [int] NULL,
	[SumUncodedDealer] [int] NULL,
	[SumEventAlreadySelected] [int] NULL,
	[SumNonLatestEvent] [int] NULL,
	[SumInvalidOwnershipCycle] [int] NULL,
	[SumRecontactPeriod] [int] NULL,
	[SumInvalidVehicleRole] [int] NULL,
	[SumCrossBorderAddress] [int] NULL,
	[SumCrossBorderDealer] [int] NULL,
	[SumExclusionListMatch] [int] NULL,
	[SumInvalidEmailAddress] [int] NULL,
	[SumBarredEmailAddress] [int] NULL,
	[SumBarredDomain] [int] NULL,
	[SumWrongEventType] [int] NULL,
	[SumMissingStreet] [int] NULL,
	[SumMissingPostCode] [int] NULL,
	[SumMissingEmail] [int] NULL,
	[SumMissingTelephone] [int] NULL,
	[SumMissingStreetAndEmail] [int] NULL,
	[SumMissingTelephoneAndEmail] [int] NULL,
	[SumPartySuppression] [int] NULL,
	[SumPostalSuppression] [int] NULL,
	[SumEMailSuppression] [int] NULL,
	[SumInvalidModel] [int] NULL,
	[ModelDescription] [nvarchar](200) NULL,
	[OtherRejectionsManual] [int] NULL
) ON [PRIMARY]
