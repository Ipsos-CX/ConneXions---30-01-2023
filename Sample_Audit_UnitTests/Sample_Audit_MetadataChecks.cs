using System;
using System.Text;
using System.Data;
using System.Data.Common;
using System.Collections.Generic;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Microsoft.VisualStudio.TeamSystem.Data.UnitTesting;
using Microsoft.VisualStudio.TeamSystem.Data.UnitTesting.Conditions;

namespace Sample_Audit_UnitTests
{
    [TestClass()]
    public class Sample_Audit_MetadataChecks : DatabaseTestClass
    {

        public Sample_Audit_MetadataChecks()
        {
            InitializeComponent();
        }

        [TestInitialize()]
        public void TestInitialize()
        {
            base.InitializeTest();
        }
        [TestCleanup()]
        public void TestCleanup()
        {
            base.CleanupTest();
        }

        [TestMethod()]
        public void FileFailureReasons()
        {
            DatabaseTestActions testActions = this.FileFailureReasonsData;
            // Execute the pre-test script
            // 
            System.Diagnostics.Trace.WriteLineIf((testActions.PretestAction != null), "Executing pre-test script...");
            ExecutionResult[] pretestResults = TestService.Execute(this.PrivilegedContext, this.PrivilegedContext, testActions.PretestAction);
            // Execute the test script
            // 
            System.Diagnostics.Trace.WriteLineIf((testActions.TestAction != null), "Executing test script...");
            ExecutionResult[] testResults = TestService.Execute(this.ExecutionContext, this.PrivilegedContext, testActions.TestAction);
            // Execute the post-test script
            // 
            System.Diagnostics.Trace.WriteLineIf((testActions.PosttestAction != null), "Executing post-test script...");
            ExecutionResult[] posttestResults = TestService.Execute(this.PrivilegedContext, this.PrivilegedContext, testActions.PosttestAction);
        }
        [TestMethod()]
        public void FileTypes()
        {
            DatabaseTestActions testActions = this.FileTypesData;
            // Execute the pre-test script
            // 
            System.Diagnostics.Trace.WriteLineIf((testActions.PretestAction != null), "Executing pre-test script...");
            ExecutionResult[] pretestResults = TestService.Execute(this.PrivilegedContext, this.PrivilegedContext, testActions.PretestAction);
            // Execute the test script
            // 
            System.Diagnostics.Trace.WriteLineIf((testActions.TestAction != null), "Executing test script...");
            ExecutionResult[] testResults = TestService.Execute(this.ExecutionContext, this.PrivilegedContext, testActions.TestAction);
            // Execute the post-test script
            // 
            System.Diagnostics.Trace.WriteLineIf((testActions.PosttestAction != null), "Executing post-test script...");
            ExecutionResult[] posttestResults = TestService.Execute(this.PrivilegedContext, this.PrivilegedContext, testActions.PosttestAction);
        }

        #region Designer support code

        /// <summary> 
        /// Required method for Designer support - do not modify 
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            Microsoft.VisualStudio.TeamSystem.Data.UnitTesting.DatabaseTestAction FileFailureReasons_TestAction;
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(Sample_Audit_MetadataChecks));
            Microsoft.VisualStudio.TeamSystem.Data.UnitTesting.Conditions.RowCountCondition rowCountCondition1;
            Microsoft.VisualStudio.TeamSystem.Data.UnitTesting.DatabaseTestAction FileTypes_TestAction;
            Microsoft.VisualStudio.TeamSystem.Data.UnitTesting.Conditions.RowCountCondition rowCountCondition2;
            this.FileFailureReasonsData = new Microsoft.VisualStudio.TeamSystem.Data.UnitTesting.DatabaseTestActions();
            this.FileTypesData = new Microsoft.VisualStudio.TeamSystem.Data.UnitTesting.DatabaseTestActions();
            FileFailureReasons_TestAction = new Microsoft.VisualStudio.TeamSystem.Data.UnitTesting.DatabaseTestAction();
            rowCountCondition1 = new Microsoft.VisualStudio.TeamSystem.Data.UnitTesting.Conditions.RowCountCondition();
            FileTypes_TestAction = new Microsoft.VisualStudio.TeamSystem.Data.UnitTesting.DatabaseTestAction();
            rowCountCondition2 = new Microsoft.VisualStudio.TeamSystem.Data.UnitTesting.Conditions.RowCountCondition();
            // 
            // FileFailureReasons_TestAction
            // 
            FileFailureReasons_TestAction.Conditions.Add(rowCountCondition1);
            resources.ApplyResources(FileFailureReasons_TestAction, "FileFailureReasons_TestAction");
            // 
            // rowCountCondition1
            // 
            rowCountCondition1.Enabled = true;
            rowCountCondition1.Name = "rowCountCondition1";
            rowCountCondition1.ResultSet = 1;
            rowCountCondition1.RowCount = 2;
            // 
            // FileTypes_TestAction
            // 
            FileTypes_TestAction.Conditions.Add(rowCountCondition2);
            resources.ApplyResources(FileTypes_TestAction, "FileTypes_TestAction");
            // 
            // rowCountCondition2
            // 
            rowCountCondition2.Enabled = true;
            rowCountCondition2.Name = "rowCountCondition2";
            rowCountCondition2.ResultSet = 1;
            rowCountCondition2.RowCount = 6;
            // 
            // FileFailureReasonsData
            // 
            this.FileFailureReasonsData.PosttestAction = null;
            this.FileFailureReasonsData.PretestAction = null;
            this.FileFailureReasonsData.TestAction = FileFailureReasons_TestAction;
            // 
            // FileTypesData
            // 
            this.FileTypesData.PosttestAction = null;
            this.FileTypesData.PretestAction = null;
            this.FileTypesData.TestAction = FileTypes_TestAction;
        }

        #endregion


        #region Additional test attributes
        //
        // You can use the following additional attributes as you write your tests:
        //
        // Use ClassInitialize to run code before running the first test in the class
        // [ClassInitialize()]
        // public static void MyClassInitialize(TestContext testContext) { }
        //
        // Use ClassCleanup to run code after all tests in a class have run
        // [ClassCleanup()]
        // public static void MyClassCleanup() { }
        //
        #endregion

        private DatabaseTestActions FileFailureReasonsData;
        private DatabaseTestActions FileTypesData;
    }
}
