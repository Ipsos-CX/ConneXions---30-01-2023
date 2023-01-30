CREATE TABLE [dbo].[Questionnaires]
(
	QuestionnaireID			INT NOT NULL IDENTITY(1,1), 
	Questionnaire			dbo.Requirement NOT NULL, 
    IncludeInInviteMatrix		INT NULL DEFAULT 1			-- TASK 1009 | TASK 1017
)
