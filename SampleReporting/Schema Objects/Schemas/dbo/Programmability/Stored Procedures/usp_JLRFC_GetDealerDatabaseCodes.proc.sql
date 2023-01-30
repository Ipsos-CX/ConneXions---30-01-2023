CREATE PROCEDURE [dbo].[usp_JLRFC_GetDealerDatabaseCodes]
       
       @Survey	nvarchar(50),
       @Market	nvarchar(50),
       @Brand	nvarchar(50)
AS

BEGIN
/*
	Purpose:	This selects all valid dealer codes from dealerdatabase for survey, market, brand
		
	Version			Date			Developer			Comment
	1.0				25/06/2015		John McCabe			Used Only by JM's filechecker application

*/

       -- SET NOCOUNT ON added to prevent extra result sets from
       -- interfering with SELECT statements.
       SET NOCOUNT ON;

		-- Insert statements for procedure here
       SELECT	DealerCode,DealerCode_GDD
       FROM		EventX_DealerTable_GDD
       WHERE	Market		= @Market
				AND Survey	= @Survey
				AND Brand	= @Brand
END	
