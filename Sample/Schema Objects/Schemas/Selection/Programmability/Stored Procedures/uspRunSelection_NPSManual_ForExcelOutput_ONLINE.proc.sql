CREATE PROCEDURE [Selection].[uspRunSelection_NPSManual_ForExcelOutput_ONLINE]
    @SelectionDate VARCHAR(8) ,
    @MIS VARCHAR(6) ,
    @ManufacturerPartyID TINYINT ,
    @CountryID SMALLINT
	/*
	
	SELECT distinct CONVERT(VARCHAR(8), SelectionDate)  from Selection.NPS_SelectedEvents
	[Selection].[uspRunSelection_NPSManual_ForExcelOutput_ONLINE]	'20150107','18 MIS',2,12
	select * FROM    Selection.NPS_SelectedEvents

	*/
AS
    DECLARE @ErrorNumber INT
    DECLARE @ErrorSeverity INT
    DECLARE @ErrorState INT
    DECLARE @ErrorLocation NVARCHAR(500)
    DECLARE @ErrorLine INT
    DECLARE @ErrorMessage NVARCHAR(2048)

	-- new stuff
    DECLARE @RowCount INT
    DECLARE @RetVal INT  -- returned value
    DECLARE @ProcedureName VARCHAR(100)
	DECLARE @CountryName NVARCHAR(100)

	SELECT @CountryName = [Country] FROM ContactMechanism.Countries
	WHERE CountryID = @CountryID

    SET @ProcedureName = OBJECT_NAME(@@PROCID)

   -- TRUNCATE TABLE dbo.Timings
    BEGIN TRY
        SET NOCOUNT ON
--------------------------------------------------------------------------------			
		/* OUTPUTTING - ALL DATA */
		
        --SELECT  RespondentPartyID AS PartyID ,
        --        CaseID AS [ID] ,
        --        FullModel ,
        --        Model ,
        --        sType ,
        --        CarReg ,
        --        Title ,
        --        Initial ,
        --        Surname ,
        --        Fullname ,
        --        DearName ,
        --        CoName ,
        --        Add1 ,
        --        Add2 ,
        --        Add3 ,
        --        Add4 ,
        --        Add5 ,
        --        Add6 ,
        --        Add7 ,
        --        Add8 ,
        --        Add9 ,
        --        CTRY ,
        --        EmailAddress ,
        --        Dealer ,
        --        sno ,
        --        ccode ,
        --        modelcode ,
        --        lang ,
        --        manuf ,
        --        gender ,
        --        qver ,
        --        blank ,
        --        etype ,
        --        reminder ,
        --        week ,
        --        test ,
        --        SampleFlag ,
        --        '' AS NewSurveyFile ,
        --        ITYPE ,
        --        '' AS Expired ,
        --        EventDate ,
        --        VIN ,
        --        DealerCode ,
        --        GDDDealerCode AS GlobalDealerCode ,
        --        HomeNumber ,
        --        WorkNumber ,
        --        MobileNumber ,
        --        ModelYear ,
        --        '' AS CustomerUniqueID ,
        --        OwnershipCycle ,
        --        '' AS PrivateOwner ,
        --        '' AS SalesEmployeeCode ,
        --        '' AS SalesEmployeeName ,
        --        '' AS ServiceEmployeeCode ,
        --        '' AS ServiceEmployeeName ,
        --        DealerPartyID ,
        --        Password ,
        --        ReportingDealerPartyID ,
        --        VariantID AS ModelVariantCode ,
        --        ModelVariant AS ModelVariantDescription ,
        --        CLPSalesCaseID ,
        --        CLPServiceCaseID ,
        --        RoadSideCaseID ,
        --        NewUsed ,
        --        1 AS CarOwnership ,
        --        MIS ,
        --        CTRY AS Market ,
        --        SuperNationalRegion
        --FROM    Selection.NPS_SelectedEvents_ForExcelOutput
        --WHERE   CONVERT(VARCHAR(8), SelectionDate,112) = @SelectionDate
        --        AND MIS = @MIS
        --        AND manuf = @ManufacturerPartyID
        --        AND ccode = @CountryID


-----------------------------------------------------------------------------------------



		
	
		/* OUTPUTTING - ONLINE ALL FILE */
		
        EXEC @RetVal = uspUpdateTimings @ProcessName = @ProcedureName,
            @SubProcessName = 'OUTPUTTING - ONLINE ALL FILE'        					                    
	
        SELECT  ISNULL(RespondentPartyID, '') AS PartyID ,
                NewCaseID AS [ID] ,
                ISNULL(FullModel, '') AS FullModel ,
                ISNULL(Model, '') AS Model ,
                ISNULL(sType, '') AS sType ,
                ISNULL(CarReg, '') AS CarReg ,
                ISNULL(Title, '') AS Title ,
                ISNULL(Initial, '') AS Initial ,
                ISNULL(Surname, '') AS Surname ,
                ISNULL(Fullname, '') AS Fullname ,
                ISNULL(DearName, '') AS DearName ,
                ISNULL(CoName, '') AS CoName ,
                ISNULL(Add1, '') AS Add1 ,
                ISNULL(Add2, '') AS Add2 ,
                ISNULL(Add3, '') AS Add3 ,
                ISNULL(Add4, '') AS Add4 ,
                ISNULL(Add5, '') AS Add5 ,
                ISNULL(Add6, '') AS Add6 ,
                ISNULL(Add7, '') AS Add7 ,
                ISNULL(Add8, '') AS Add8 ,
                ISNULL(Add9, '') AS Add9 ,
                @CountryName AS CTRY ,
                ISNULL(EmailAddress, '') AS EmailAddress ,
                ISNULL(Dealer, '') AS Dealer ,
                ISNULL(sno, '') AS sno ,
                ISNULL(ccode, '') AS ccode ,
                ISNULL(modelcode, '') AS modelcode ,
                ISNULL(lang, '') AS lang ,
                ISNULL(manuf, '') AS manuf ,
                ISNULL(gender, '') AS gender ,
                ISNULL(qver, '') AS qver ,
                ISNULL(blank, '') AS blank ,
                ISNULL(etype, '') AS etype ,
                ISNULL(reminder, '') AS reminder ,
                2 AS [week] ,
                ISNULL(test, '') AS test ,
                ISNULL(SampleFlag, '') AS SampleFlag ,
                N'' AS NewSurveyFile ,
                ISNULL(ITYPE, '') AS ITYPE ,
                N'' AS Expired ,
                ISNULL(EventDate, '') AS EventDate ,
                ISNULL(VIN, '') AS VIN ,
                ISNULL(DealerCode, '') AS DealerCode ,
                ISNULL(GDDDealerCode, '') AS GlobalDealerCode ,
                ISNULL(TCC.CountryCode, '')
                + [Selection].[udfStripCharForNPSMobile](HomeNumber) AS HomeNumber ,
                ISNULL(TCC.CountryCode, '')
                + [Selection].[udfStripCharForNPSMobile](WorkNumber) AS WorkNumber ,
                ISNULL(TCC.CountryCode, '')
                + [Selection].[udfStripCharForNPSMobile](MobileNumber) AS MobileNumber ,
                ISNULL(ModelYear, '') AS ModelYear ,
                N'' AS CustomerUniqueID ,
                ISNULL(OwnershipCycle, '') AS OwnershipCycle ,
                N'' AS PrivateOwner ,
                N'' AS SalesEmployeeCode ,
                N'' AS SalesEmployeeName ,
                N'' AS ServiceEmployeeCode ,
                N'' AS ServiceEmployeeName ,
                ISNULL(DealerPartyID, '') AS DealerPartyID ,
                ISNULL([Password], '') AS [Password] ,
                ISNULL(ReportingDealerPartyID, '') AS ReportingDealerPartyID ,
                ISNULL(VariantID, '') AS ModelVariantCode ,
                ISNULL(ModelVariant, '') AS ModelVariantDescription
        FROM    Selection.NPS_SelectedEvents_ForExcelOutput SE
                LEFT JOIN Selection.NPS_TelphoneCountryCode TCC ON SE.ccode = TCC.CountryId
        WHERE   CONVERT(VARCHAR(8), SelectionDate, 112) = @SelectionDate
                AND MIS = @MIS
                AND manuf = @ManufacturerPartyID
                AND ccode = @CountryID 



 --       SET @Rowcount = @@ROWCOUNT
 --       EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount




	--	/* OUTPUTTING - SMS FILE */
	
		
		
 --       EXEC @RetVal = uspUpdateTimings @ProcessName = @ProcedureName, @SubProcessName = 'OUTPUTTING - SMS FILE'        					                    		
		
 --       SELECT DISTINCT

 --               CASE 
	--				 WHEN MobileNumber LIKE X.PrefixPattern THEN ISNULL(TCC.CountryCode, '') + [Selection].[udfStripCharForNPSMobile](MobileNumber)
 --                    WHEN HomeNumber LIKE Y.PrefixPattern THEN ISNULL(TCC.CountryCode, '') + [Selection].[udfStripCharForNPSMobile](HomeNumber)
 --                    WHEN WorkNumber LIKE Z.PrefixPattern THEN ISNULL(TCC.CountryCode, '') + [Selection].[udfStripCharForNPSMobile](WorkNumber)
 --               END AS Mobile , 
		
 --               RespondentPartyID ,
 --               sType ,
 --               CaseID AS [ID] ,
 --               password
 --       FROM    Selection.NPS_SelectedEvents SE 
                
 --               LEFT JOIN Selection.NPS_MobilePhoneCodes X ON (SE.ccode = X.CountryId) AND (SE.MobileNumber LIKE X.PrefixPattern)
	--			LEFT JOIN Selection.NPS_MobilePhoneCodes Y ON (SE.ccode = Y.CountryId) AND (SE.HomeNumber LIKE Y.PrefixPattern)
	--			LEFT JOIN Selection.NPS_MobilePhoneCodes Z ON (SE.ccode = Z.CountryId) AND (SE.WorkNumber LIKE Z.PrefixPattern) 
                
 --               LEFT JOIN Selection.NPS_TelphoneCountryCode TCC ON SE.ccode = TCC.CountryId

 --       WHERE   (SelectionDate = @SelectDate) AND 
 --               (MIS = @MIS) AND
 --               (Manuf = @ManufacturerPartyID) AND
 --               (ccode = @CountryID) AND         
			
			
	--			(ISNULL(EmailAddress,'') = '') AND
			
 --               (CASE WHEN MobileNumber LIKE X.PrefixPattern THEN MobileNumber
 --                    WHEN HomeNumber LIKE Y.PrefixPattern THEN HomeNumber
 --                    WHEN WorkNumber LIKE Z.PrefixPattern THEN WorkNumber
 --                    ELSE NULL
 --               END IS NOT NULL)
        
 --       ORDER BY CaseID
        
 --       SET @Rowcount = @@ROWCOUNT
 --       EXEC @RetVal = uspUpdateTimings @Id = @RetVal, @NumberOfRowsProcessed = @RowCount
                                                

	--COMMIT TRANSACTION;		
    END TRY


    BEGIN CATCH
	

        EXEC usp_RethrowError

    END CATCH

    RETURN 0