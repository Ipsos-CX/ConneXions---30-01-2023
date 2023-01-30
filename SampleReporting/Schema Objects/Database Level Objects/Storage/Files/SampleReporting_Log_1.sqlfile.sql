ALTER DATABASE [$(DatabaseName)]
    ADD LOG FILE (NAME = [SampleReporting_Log], FILENAME = 'D:\aa08.log01\SampleReporting_Log.ldf', SIZE = 1475904 KB, MAXSIZE = 2097152 MB, FILEGROWTH = 10 %);

