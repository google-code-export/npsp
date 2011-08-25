/*
 * Test Class for type ahead feature.
 * authors: Team Kick Ass; Veronica Waters, Evan Callahan, Derek Dsouza, Mike Fullmore
 * date 04/27/2011
*/

public with sharing class TestTypeAheadController {

	private Account selectedAccount;
	private String selectedId;
	
	public Account getSelectedAccount(){return this.selectedAccount;}
	public String getSelectedId(){return this.selectedId;}
	
	public void setSelectedId(String pSelectedId){this.selectedId = pSelectedId;}
	
	public TestTypeAheadController(){
		
	}
	
	public void selectRecord(){
		System.debug('selected Id = ' + this.selectedId);
		if(this.selectedId != null){
			this.selectedAccount = [select Id, Name from Account where Id = : this.selectedId];
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'You selected : ' + this.selectedAccount.Name));
		}else{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'didnt work'));
		}
		System.debug('selected account ' + this.selectedAccount);
	}
}