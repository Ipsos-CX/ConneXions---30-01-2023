CREATE PROCEDURE [SelectionOutput].[uspGetAdhocCases]@ReqID [dbo].[RequirementID]

AS

INSERT SelectionOutput.AdhocSelection_FinalOutput
	   
	   (PartyID
      ,FullModel
      ,Model
      ,sType
      ,CarReg
      ,Title
      ,Initial
      ,Surname
      ,Fullname
      ,DearName
      ,CoName
      ,Add1
      ,Add2
      ,Add3
      ,Add4
      ,Add5
      ,Add6
      ,Add7
      ,Add8
      ,Add9
      ,CTRY
      ,EmailAddress
      ,Dealer
      ,sno
      ,ccode
      ,modelcode
      ,lang
      ,manuf
      ,gender
      ,qver
      ,blank
      ,etype
      ,reminder
      ,[week]
      ,test
      ,SampleFlag
      ,SurveyFile
      ,ITYPE
      ,Expired
      ,EventDate
      ,VIN
      ,DealerCode
      ,GlobalDealerCode
      ,LandPhone
      ,WorkPhone
      ,MobilePhone
      ,ModelYear
      ,CustomerUniqueID
      ,OwnershipCycle
      ,EmployeeCode
      ,EmployeeName
      ,DealerPartyID
      ,[Password]
      ,ReportingDealerPartyID
      ,ModelVariantCode
      ,ModelVariantDescription
      ,SelectionDate
      ,CampaignId
      ,PilotCode)



SELECT PartyID
      ,FullModel
      ,Model
      ,sType
      ,CarReg
      ,Title
      ,Initial
      ,Surname
      ,Fullname
      ,DearName
      ,CoName
      ,Add1
      ,Add2
      ,Add3
      ,Add4
      ,Add5
      ,Add6
      ,Add7
      ,Add8
      ,Add9
      ,CTRY
      ,EmailAddress
      ,Dealer
      ,sno
      ,ccode
      ,modelcode
      ,lang
      ,manuf
      ,gender
      ,qver
      ,blank
      ,etype
      ,reminder
      ,[week]
      ,test
      ,SampleFlag
      ,SurveyFile
      ,ITYPE
      ,Expired
      ,EventDate
      ,VIN
      ,DealerCode
      ,GlobalDealerCode
      ,LandPhone
      ,WorkPhone
      ,MobilePhone
      ,ModelYear
      ,CustomerUniqueID
      ,OwnershipCycle
      ,EmployeeCode
      ,EmployeeName
      ,DealerPartyID
      ,[Password]
      ,ReportingDealerPartyID
      ,ModelVariantCode
      ,ModelVariantDescription
      ,SelectionDate
      ,CampaignId
      ,PilotCode

  FROM		SelectionOutput.AdhocSelection_OnlineOutput
  WHERE		RequirementID = @ReqID
  ORDER BY	PartyID