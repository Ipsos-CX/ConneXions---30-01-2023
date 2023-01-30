ALTER TABLE [SampleReport].[GlobalReportDealerRegionAggregate]
	ADD CONSTRAINT [PK_GlobalReportDealerRegionAggregate]
	PRIMARY KEY (ReportYear, ReportMonth, SummaryType, Brand, Market, Questionnaire, SuperNationalRegion, BusinessRegion, SubNationalTerritory, SubNationalRegion, DealerCode, DealerName)