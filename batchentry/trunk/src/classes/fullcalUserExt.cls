public with sharing class fullcalUserExt {
	
	Apexpages.Standardcontroller con; 

	public fullcalUserExt( Apexpages.Standardcontroller sc) {		con = sc;	} 
     	
	public class UserClass { 
		public User u {get; set; } 
		public Chatter_Calendar_Prefs__c setting { get; set; }	  
	}
    
    public UserClass colorUser { get    {
       	if ( colorUser == null ) {
	        User u  =  [select id,name,title,CurrentStatus, SmallPhotoUrl from User where id = :con.getId() limit 1];
            colorUser = new UserClass();  
            colorUser.u = u;
            colorUser.setting = ChatterCalPrefs.getSettings( u.id ); 
	    }
        return colorUser;
    }   
    private set;   }
     
   	string qstr(string s) { 
		String ret = Apexpages.currentPage().getParameters().get(s) ;
		if (ret != null ) 
			ret = String.escapeSingleQuotes( ret );
		return ret; 
	}
	
    public PageReference saveColor() { 
    	try {
        	
    		Chatter_Calendar_Prefs__c setting = ChatterCalPrefs.getSettings( con.getId() ); 
    		setting.color__c = qstr('color');
            setting.background_color__c = qstr('background');
            Database.upsert(setting);
            
        } catch (system.exception e) {
            ApexPages.addMessages(e);
        }
    	
    	return new Pagereference('/apex/fullcalGroup');
    }

	public static testmethod void t1() { 
    	Test.setCurrentPage( Page.fullcalColorSettings );
    	User createUser = createUser();
    	insert createUser;
    	System.assertEquals(createUser.Alias, 'standt');
    	
    	fullcalUserExt f = new fullcalUserExt(new Apexpages.Standardcontroller(createUser));
    	
    	ApexPages.currentPage().getParameters().put('color','color');
    	ApexPages.currentPage().getParameters().put('background','background');
    	Pagereference p = f.saveColor();
    //	system.debug(LoggingLevel.INFO, p);
    	
    	//system.debug(LoggingLevel.INFO, f.backgroundcolor);
    	//system.debug(LoggingLevel.INFO,  f.color);
    	//system.debug(LoggingLevel.INFO,  f.setting);
    	
    //	system.debug(LoggingLevel.INFO, f.colorUser);
    	UserClass u = f.colorUser;
    	system.assert( u.setting.color__c == 'color');
    	
	}
	    //use this method to return a user sobject
    public static User createUser(){
        Profile pr = [select id from profile where name='Standard User' limit 1]; 
        
        User u = new User(alias = 'standt', 
                          email='standarduser@testorg.com', 
                          emailencodingkey='UTF-8', 
                          lastname='Testing', 
                          languagelocalekey='en_US', 
                          localesidkey='en_US', 
                          profileid = pr.Id, 
                          timezonesidkey='America/Los_Angeles', 
                          username='standard' + String.valueOf(System.now().getTime()) + '@testorg.com');
            
        return u;
    }
}