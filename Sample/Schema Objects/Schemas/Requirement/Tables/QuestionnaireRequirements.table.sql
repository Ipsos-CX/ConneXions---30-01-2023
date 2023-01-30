CREATE TABLE [Requirement].[QuestionnaireRequirements] (
    [RequirementID]                    [dbo].[RequirementID]       NOT NULL,
    [CountryID]                        [dbo].[CountryID]           NOT NULL,
    [StartDays]                        INT                         NOT NULL,
    [EndDays]                          INT                         NOT NULL,
    [QuestionnaireIncompatibilityDays] INT                         NOT NULL,
    [ManufacturerPartyID]              [dbo].[ManufacturerPartyID] NULL,
    [LanguageID]                       [dbo].[LanguageID]          NULL,
    [OwnershipCycle]                   [dbo].[OwnershipCycle]      NULL,
    [EventCategoryID]				   [dbo].[EventCategoryID]	   NULL,
    [QuestionnaireVersion]			   [dbo].[QuestionnaireVersion]					   NULL,
    [RelativeRecontactDays]				INT NULL				,
    [ValidateSaleTypes]					INT NULL				,
    [ValidateAFRLCodes]					INT NULL				,
    [UseLatestEmailTable]				INT NOT NULL,
    [FilterOnDealerPilotOutputCodes]	BIT NULL,
    [CRMSaleTypeCheck]					BIT NULL,
    [CATILanguageID]                    [dbo].[LanguageID]          NULL,
    [PDIFlagCheck]						BIT NULL,					-- 05-09-2107 - BUG
    [IgnoreWarranty]					BIT NULL,					-- 18-05-2018 - BUG 14557
    [NumberOfDaysOfLastContact]			INT NULL,					-- 10-09-2018 - BUG 14820
    [NumberOfDaysToExclude]				INT NULL,					-- 15-11-2018 - BUG 14820
	[ValidateSaleTypeFromDate]			DATETIME NULL,				-- 23-01-2020 - BUG 16816 
	[ValidateCommonSaleType]			INT NULL					-- 17-06-2022 - TASK 900 Selection Rule Changes for Sales CXP
);



