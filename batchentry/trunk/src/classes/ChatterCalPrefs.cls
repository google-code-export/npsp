public with sharing class ChatterCalPrefs {
	
	public string recentGroup { get; set; } 
	public string recentView { get; set; } 
	public string color { get; set; } 
	public string backgroundcolor { get; set; } 
    
    public ChatterCalPrefs() {  
    	Chatter_Calendar_Prefs__c setting = getSettings( UserInfo.getUserId() ); 
    	if (setting != null) { // if no default we can still have a null setting 
    		recentGroup = setting.Recent_Group__c; 
    		recentView = setting.Recent_View__c;
    		color = setting.color__c;
    		backgroundcolor = setting.background_color__c;
    	}	
    }
	
	public void saveView(String view) {
        try {
        	Chatter_Calendar_Prefs__c setting = getSettings( UserInfo.getUserId() ); 
    		setting.Recent_View__c = String.escapeSingleQuotes( view );
            Database.upsert(setting);
        } catch (system.exception e) {
            ApexPages.addMessages(e);
        }
    }	
	public void savePrefs() {
        try {
        	String input = System.currentPageReference().getParameters().get('prefspec');
        	Chatter_Calendar_Prefs__c setting = getSettings( UserInfo.getUserId() ); 
            setting.Recent_Group__c = String.escapeSingleQuotes( input );
            Database.upsert(setting);
        } catch (system.exception e) {
            ApexPages.addMessages(e);
        }
    }
    
	public static Chatter_Calendar_Prefs__c getSettings( id id ) {
		Chatter_Calendar_Prefs__c setting = Chatter_Calendar_Prefs__c.getValues( id ); 
		if ( setting == null ) {
			setting = new Chatter_Calendar_Prefs__c(setupownerid = id);
		} 
		return setting;
	} 
 	
    public static testMethod void t1() {
    	ChatterCalPrefs lp = new ChatterCalPrefs();
    	//system.assert( lp.recentGroup != null );
    	
    	Apexpages.currentPage().getParameters().put('prefspec','foo');
    	lp.savePrefs();
    	Chatter_Calendar_Prefs__c setting = Chatter_Calendar_Prefs__c.getValues(UserInfo.getUserId());
    	system.assertEquals('foo',setting.Recent_Group__c); 
    	
    	Database.delete(setting);
    	ChatterCalPrefs lp2 = new ChatterCalPrefs();
    	Apexpages.currentPage().getParameters().put('prefspec','bar');
    	lp2.savePrefs();
    	setting = Chatter_Calendar_Prefs__c.getValues(UserInfo.getUserId());
    	system.assertEquals('bar',setting.Recent_Group__c); 
    	
    	lp2.saveView('view');
    	Chatter_Calendar_Prefs__c p = ChatterCalPrefs.getSettings( UserInfo.getUserId() );
    	system.assert( p != null);
   }
}