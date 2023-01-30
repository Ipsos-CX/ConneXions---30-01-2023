CREATE TABLE [dbo].[UncodedDealerReport]
(
	Country											NVARCHAR(500),
	Brand											VARCHAR(20),
	Survey											VARCHAR(50),
	Dealer_Code										VARCHAR(20),
	Dealer_Code_SetUp_For_Other_Surveys_InMarket	NVARCHAR(200),
	DealerName_From_SVCRM							NVARCHAR(max),
	OtherBrandInMarket								VARCHAR(50),
	Comment											VARCHAR(1000),
	Date_First_Loaded								DATE,
	Count_Received_ToDate							BIGINT,
	Filenames										NVARCHAR(MAX)
)
