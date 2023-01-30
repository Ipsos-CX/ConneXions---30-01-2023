CREATE PROCEDURE [dbo].[uspSendCATISelectionEmails]
    @To VARCHAR(500) = 'stephen.nunn@ipsos.com;clare.yetton@ipsos.com;simone.king@ipsos.com;andrew.erskine@ipsos.com;steve.vidler@ipsos.com;Alan.Wayman@ipsos.com' ,
    --@To VARCHAR(500) =  'chris.ledger@ipsos.com',
    @From VARCHAR(100) = 'CNX_JLR_Output@ipsos-online.com',
    --@cc VARCHAR(1000) = 'chris.ledger@ipsos.com' 
    @cc VARCHAR(1000) = 'tim.wardle@ipsos.com;dipak.gohil@ipsos.com;chris.ledger@ipsos.com;chris.ross@ipsos.com' ,
    @Folder VARCHAR(100) = '\\1005796-CXNSQLP\Sampling\DataOutput\SelectionOutputCATI\'
	
AS

/*
	Purpose: Email Details of CATI Selection Outputs
		
	Version			Date			Developer			Comment
	1.0				2017-05-15		Chris Ledger		Added to Solution
	1.1				2017-10-26		Chris Ledger		Add steven.vidler@gfk.com
	1.2				2018-05-07		Chris Ledger		Change @Date to (CURRENT TIME - 3 HRS) so non CATI Combined output will not be included (N.B. This is overnight China outputs and reoutputs)  
	1.3				2019-04-11		Chris Ross			BUG 15345 - Update to use IPSOS email addresses.
	1.4				2019-07-22		Chris Ledger		Change @From and @Folder
	1.5				2019-12-06		Chris Ledger		Add Alan.Wayman@ipsos.com
*/
	
    BEGIN TRY	

		-- 
		-- Declare All local variables 
		--
		SET NOCOUNT ON

		DECLARE @ErrorNumber INT
		DECLARE @ErrorSeverity INT
		DECLARE @ErrorState INT
		DECLARE @ErrorLocation NVARCHAR(500)
		DECLARE @ErrorLine INT
		DECLARE @ErrorMessage NVARCHAR(2048)
		
	    DECLARE @Attachments VARCHAR(MAX)        
		DECLARE @Body VARCHAR(MAX)
        DECLARE @Now DATETIME
        DECLARE @Date DATE	
        DECLARE @Retval INT	        		                

        SET @Now = GETDATE() 
        SET @Date = DATEADD(HOUR,-3,GETDATE())		-- V1.2
		
	-- get latest files to email
        INSERT  INTO dbo.SelectionFiles
                ( SelectionFileName
                )
                SELECT  FileName
                FROM    [$(AuditDB)].dbo.Files F
                        LEFT JOIN dbo.SelectionFiles S ON F.FileName = S.SelectionFileName
                        LEFT JOIN  [$(AuditDB)].dbo.FileTypes FT on f.FileTypeID  = ft.FileTypeID
                WHERE   ft.FileType IN ('Selection Output','CRC Uncoded Agent Names')
                        AND ActionDate >= @Date
                        AND S.SelectionFileName IS NULL 
                        
			
        SELECT  @Attachments = COALESCE(@Attachments + CHAR(13) + CHAR(10), '') + @Folder
                + SelectionFileName
        FROM    dbo.SelectionFiles
        WHERE   TimeEmailed IS NULL 


		SELECT @Body = 'The following file selection output files have been created....'  + CHAR(13)  + CHAR(10) + @Attachments
	

        IF @Attachments IS NOT NULL
            BEGIN

                EXEC @Retval = msdb.dbo.sp_send_dbmail @profile_name = 'DBAProfile',
                    @recipients = @To---  ; ...n ' 
                    , @copy_recipients = @cc --  'copy_recipient  ; ...n ' 
			 --,  @blind_copy_recipients =  'blind_copy_recipient  ; ...n ' 
                    , @from_address = @From 
			 --,  @reply_to =  'reply_to'  
                    , @subject = 'Requested Selection Files',
                    @body = @body
			 --,  @body_format =  'body_format' 
			 --,  @importance =  'importance' 
			 --,  @sensitivity =  'sensitivity' 
              --      , @file_attachments = @Attachments 
			 --,  @query =  'query' 
			 --,  @execute_query_database =  'execute_query_database' 
			-- ,  @attach_query_result_as_file =  attach_query_result_as_file 
			-- ,  @query_attachment_filename =  query_attachment_filename 
			 --,  @query_result_header =  query_result_header 
			 --,  @query_result_width =  query_result_width 
			 --,  @query_result_separator =  'query_result_separator' 
			 --,  @exclude_query_output =  exclude_query_output 
			 --,  @append_query_error =  append_query_error 
			 --,  @query_no_truncate =  query_no_truncate  
			 --, @query_result_no_padding =  @query_result_no_padding  
			 --,  @mailitem_id =  mailitem_id   OUTPUT 
			 
                IF @Retval <> 0
                    BEGIN
                        RAISERROR ( 'Mailing failed',16,1)
                    END
                
		
                UPDATE  T
                SET     TimeEmailed = @Now
                FROM    dbo.SelectionFiles T
                WHERE   TimeEmailed IS NULL
          
            END
    
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
    