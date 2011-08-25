/*
 * TypeAheadDataController controls what data the json page renders.
 * authors: Team Kick Ass; Veronica Waters, Evan Callahan, Derek Dsouza, Mike Fullmore
 * date 04/27/2011
*/

public with sharing class TypeAheadDataController {

	private List<ReturnData> dataRecords;
	private String errors;
	
	public List<ReturnData> getDataRecords(){return this.dataRecords;}
	public String getErrors(){return this.errors;}
	
	public TypeAheadDataController(){
		String typeSearch = ApexPages.currentPage().getParameters().get('term');
		String obj = ApexPages.currentPage().getParameters().get('obj');
		this.dataRecords = new List<ReturnData>();
		
		try{
			for(Sobject data : Database.query('select Id, Name from ' + obj + ' where Name like \'%' + typeSearch + '%\' limit 1000')){
				this.dataRecords.add(new ReturnData(data.get('Id'), data.get('Name')));
			}
		}catch(QueryException e){
			this.errors = e.getMessage();
		}
	} 
	
	public class ReturnData{
		Id recordId;
		String recordName;
		
		public ReturnData(Object pRecordId, Object pRecordName){
			this.recordId = String.valueOf(pRecordId);
			this.recordName = String.valueOf(pRecordName);
		}
		
		public Id getRecordId(){return this.recordId;}
		public String getRecordName(){return this.recordName;}
	}
	
	static testMethod void testTypeAheadDataController(){
		Account acc;
		List<Account> accList = new List<Account>();
		PageReference p;
		TypeAheadDataController tadc;
		
		for(Integer i = 0; i < 3; i++){	
			acc = new Account(Name = 'Test ' + String.valueOf(i));
			accList.add(acc);
		}
		
		insert accList;
		System.assertNotEquals(null, accList[0].Id);
		System.assertNotEquals(null, accList[1].Id);
		System.assertNotEquals(null, accList[2].Id);
		
		p = Page.TypeAheadData;
		p.getParameters().put('term', 'Tes');
		p.getParameters().put('obj', 'Account');
		
		Test.setCurrentPage(p);
		tadc = new TypeAheadDataController();
		System.assertEquals(null, tadc.getErrors());
		System.assert(tadc.getDataRecords().size() >= 3);
		System.assertNotEquals(null, tadc.getDataRecords()[0].getRecordId());
		System.assertNotEquals(null, tadc.getDataRecords()[0].getRecordName());
		
		//negitive test
		p = Page.TypeAheadData;
		p.getParameters().put('term', 'Tes');
		p.getParameters().put('obj', 'NEGTIVE_Account');
		
		Test.setCurrentPage(p);
		tadc = new TypeAheadDataController();
		System.assertNotEquals(null, tadc.getErrors());
	}
}