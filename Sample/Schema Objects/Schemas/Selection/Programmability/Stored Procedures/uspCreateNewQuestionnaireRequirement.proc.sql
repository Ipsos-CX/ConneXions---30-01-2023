CREATE         Procedure [Selection].[uspCreateNewQuestionnaireRequirement]
				(
				@QuestReqName NVARCHAR(100),
				@EventTypeID TINYINT,
				@CountryID SMALLINT,
				@ManufacturerPartyID INT,
				@ProgrammeID INT,
				@EndDays SMALLINT,
				@UseLatestEmail INT
				)

as

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

--select * from countries

Begin Tran

Declare	@QuestReqID Int
Declare @ProductID Int
Declare @PrevQuest Int
Declare @FromDate Datetime

Set	@FromDate = Current_TimeStamp

Insert	 [Requirement].Requirements
	(
	RequirementTypeID,
	Requirement,
	RequirementCreationDate
	)
Select	2,
	@QuestReqName,
	@FromDate

Set	@QuestReqID = @@IDENTITY

Insert	Into  [Requirement].RequirementRollups
Select	@QuestReqID,
	@ProgrammeID,
	@FromDate,
	Null

Insert	Into  [Requirement].QuestionnaireRequirements (RequirementID, CountryID, StartDays, EndDays, QuestionnaireIncompatibilityDays, ManufacturerPartyID, LanguageID, OwnershipCycle, EventCategoryID, QuestionnaireVersion, RelativeRecontactDays, ValidateSaleTypes, ValidateAFRLCodes, UseLatestEmailTable, FilterOnDealerPilotOutputCodes, CRMSaleTypeCheck, CATILanguageID, PDIFlagCheck)
Select	@QuestReqID,
	@CountryID,
	-1,
	@EndDays,
	-183,
	@ManufacturerPartyID,
	Null,
	Null,
	Null,
	NULL,
	NULL,  -- added by PDoyle 18-Nov-2014 to make sp work
	NULL,
	NULL,	-- Added by CLedger to account for new AFRL codes
	@UseLatestEmail,
	NULL,	-- Added FilterOnDealerPilotOutputCodes
	NULL,	-- Added CRMSaleTypeCheck
	NULL,
	NULL
Select	@PrevQuest = Max(RequirementID) 
From 	 [Requirement].QuestionnaireRequirements qr
Where	qr.CountryID = @CountryID
	And qr.RequirementID <> @QuestReqID

SET ANSI_NULLS OFF	

Insert	Into  [Requirement].QuestionnaireAssociations
Select	Req1.RequirementID, Req2.RequirementID, @FromDate
From	(
	Select	RequirementID
	From	 [Requirement].QuestionnaireRequirements
	Where	CountryID = @CountryID
		And ManufacturerPartyID = @ManufacturerPartyID
	) as Req1
Cross Join
	(
	Select	RequirementID
	From	 [Requirement].QuestionnaireRequirements
	Where	CountryID = @CountryID
		And ManufacturerPartyID = @ManufacturerPartyID
	) as Req2
Left	Join  [Requirement].QuestionnaireAssociations qa on Req1.RequirementID = qa.RequirementIDFrom And Req2.RequirementID = qa.RequirementIDTo
Where	qa.RequirementIDFrom Is Null
	And (Req1.RequirementID = @QuestReqID OR Req2.RequirementID = @QuestReqID)

Insert	Into  [Requirement].QuestionnaireIncompatibilities
Select	Req1.RequirementID, Req2.RequirementID, @FromDate, Null
From	(
	Select	RequirementID
	From	 [Requirement].QuestionnaireRequirements
	Where	CountryID = @CountryID
		And ManufacturerPartyID = @ManufacturerPartyID
	) as Req1
Cross Join
	(
	Select	RequirementID
	From	 [Requirement].QuestionnaireRequirements
	Where	CountryID = @CountryID
		And ManufacturerPartyID = @ManufacturerPartyID
	) as Req2
Left	Join  [Requirement].QuestionnaireIncompatibilities qi on Req1.RequirementID = qi.RequirementIDFrom And Req2.RequirementID = qi.RequirementIDTo
Where	qi.RequirementIDFrom Is Null
	And (Req1.RequirementID = @QuestReqID OR Req2.RequirementID = @QuestReqID)

SET ANSI_NULLS ON

Commit Tran

END TRY
BEGIN CATCH

	SELECT
		 @ErrorNumber = Error_Number()
		,@ErrorSeverity = Error_Severity()
		,@ErrorState = Error_State()
		,@ErrorLocation = Error_Procedure()
		,@ErrorLine = Error_Line()
		,@ErrorMessage = Error_Message()

	EXEC [$(ErrorDB)].dbo.uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH