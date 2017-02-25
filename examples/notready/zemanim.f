needs date/hebrew
needs math/floats
~date ~floats ~sys ~

::
	': split if
		>single if 60 * -rot >single if + then then
		2
	else chain word? then
; is word?

: min>coord 60 /mod s>f s>f 60. f/ f+ ;
: .coord ( lon/lat -- ) min>coord  f. ;

| These three are set by invoking a 'location':
variable TZ
variable LAT
variable LONG
create LOC 60 allot

variable locations
: location ( tz lon lat name -- ) 
	create , , , last @ dup , locations link
	does> dup @ LAT ! dup cell+ @ LONG ! dup 2cell+ @ TZ ! 3cell+ @ >name count
		59 min LOC place
	;

| This is the list of locations we already know about internally:
| tz lon lat   name
-5 84:23 33:45 location Atlanta
-6 97.45 30:16 location Austin
1 -13:24 52:31 location Berlin
-3 -34:37 58:24 location Buenos-Aires
-5 76:36 39:17 location Baltimore
-5 74:5 4:36 location Bogota
-5 71:4 42:20 location Boston
-5 78:52 42:53 location Buffalo
-6 87:45 41:50 location Chicago
-5 84:31 39:6 location Cincinnati
-5 81:41 41:30 location Cleveland
-6 96:48 32:47 location Dallas
-7 104:59 39:44 location Denver
-5 83:2 42:20 location Detroit
0 5:0 36:0 location Gibraltar
-10 155:30 19:30 location Hawaii
-6 95:22 29:46 location Houston
2 -35:14 31:47 location Jerusalem
1 -26:12 -28:3 location Johannesburg
0 0:10 51:30 location London
-8 118:15 34:4 location Los-Angeles
-5 80:12 25:46 location Miami
-6 99:9 19:24 location Mexico-City
-5 74:1 40:43 location New-York
-7 95:56 41:16 location Omaha
-5 81:22 28:32 location Orlando
-5 75:10 39:57 location Philadelphia
-7 112:4 33:27 location Phoenix
-5 80:0 40:26 location Pittsburgh
-6 90:12 38:38 location Saint-Louis
-8 122:25 37:47 location San-Francisco
-8 122:20 47:36 location Seattle
-5 79:24 43:38 location Toronto
-8 123:7 49:16 location Vancouver
-5 77:0 38:55 location Washington-DC
-8 122:12 47:40 location Kirkland
| The last "location" is the default!
-8 122:8 47:37 location Bellevue

: .locs
	." City     Lat.  Long. TZ" cr
	{
		@
		dup
		>name count type_
		>xt @
		dup @ .coord
		dup cell+ @ .coord
		2cell+ @ . cr
		true
	} locations iterate
	;

locations @ cell+ @ exec
| ||
: sind ( f: deg -- sin ) deg>rad fsin ;
: cosd ( f: deg -- cos ) deg>rad fcos ;
: tand ( f: deg -- tan ) deg>rad ftan ;
: acosd ( f: cos -- degrees ) facos rad>deg ;
: atan2d  ( f: y x -- degrees ) fatan2 rad>deg ;
Jan 1 2000 gregorian>fixed constant 1JAN2k
: julian2k ( mm dd yyyy -- days-since-1/1/2000 )  | orig: yy mm ddd
	gregorian>fixed 1JAN2k - ;

variable force_dst
variable dst
: set_dst ( fixed -- ) dst? force_dst @ or dst !  ;

| ***************************************************************
| This function reduces any angle to within the first revolution 
| by subtracting or adding even multiples of 360.0 until the     
| result is >= 0.0 and < 360.0                                   
| ***************************************************************

f1 360.0 f/ fconstant INV360

| Reduce angle to within +180..+180 degrees 
|	return( x - 360.0 * floor( x * INV360 ) );
: revolution ( f: x -- f:x' ) fdup INV360 f* ffloor 360.0 f* f- ; 

| This function computes GMST0, the Greenwich Mean Sidereal Time  at 0h UT (i.e.
| the sidereal time at the Greenwhich meridian at  0h UT).  GMST is then the
| sidereal time at Greenwich at any     time of the day.  I've generalized GMST0
| as well, and define it as:  GMST0 = GMST - UT  --  this allows GMST0 to be
| computed at other times than 0h UT as well.  While this sounds somewhat
| contradictory, it is very practical:  instead of computing      GMST
| like:                                                      
|                                                                 
|  GMST = (GMST0) + UT * (366.2422/365.2422)                      
|                                                                 
| where (GMST0) is the GMST last time UT was 0 hours, one simply
| computes:                                                       
|                                                                 
|  GMST = GMST0 + UT                                              
|                                                                 
| where GMST0 is the GMST "at 0h UT" but at the current moment!   Defined in
| this way, GMST0 will increase with about 4 min a     day.  It also happens
| that GMST0 (in degrees, 1 hr = 15 degr)   is equal to the Sun's mean longitude
| plus/minus 180 degrees!    (if we neglect aberration, which amounts to 20
| seconds of arc   or 1.33 seconds of time)                                        
: GMST0 ( day -- f:gmst0 )
	0.9856002585 4.70935E-5 f+ f*
	180.0 356.0470 f+ 282.9404 f+ f+
	revolution
	;

| This function computes the Sun's position at any instant 
| Computes the Sun's ecliptic longitude and distance 
| at an instant given in d, number of days since     
| 2000 Jan 0.0.  The Sun's ecliptic latitude is not  
| computed, since it's always very near 0.           
fvariable M		| mean anomaly of the sun
fvariable w		| mean longitude of perihelion (sun's mean long =M+w)
fvariable e		| Earth's eccentricity
fvariable E		| eccentric anomaly
fvariable x
fvariable y		| x,y coordinates in orbit
fvariable v		| true anomaly

fvariable r
fvariable lon
: sunpos ( f:d -- )
	| compute mean elements
	fdup fdup		| f: d d d 
    | M = revolution( 356.0470 + 0.9856002585 * d );
	356.0470 fswap 0.9856002585
		f* f+ revolution M f!	
    | w = 282.9404 + 4.70935E-5 * d;
	4.70935E-5 f* 282.9404 f+  w f!  
	| e = 0.016709 - 1.151E-9 * d;
	1.151E-9  f* 0.016709 fswap f- e f!

    | Compute true longitude and radius vector 
	| E = M + e * RADEG * sind(M) * ( 1.0 + e * cosd(M) );
	| #define RADEG     ( 180.0 / PI ) == rad>deg
	M f@ fdup	| f: M M
	sind rad>deg e f@ f* | M (e*RADDEG*sind(M))
	f1 e f@ M f@ f* f+   | M (e*RADDEG*sind(M)) (1+e*cosd(M))
	f* f+ fdup fdup E f!

	| x = cosd(E) - e;
	cosd e f@ f- x f!
    |  y = sqrt( 1.0 - e*e ) * sind(E);
	sind f1 e f@ fdup f* f- fsqrt f* y f!
	| *r = sqrt( x*x + y*y );              /* Solar distance */
	x f@ fdup f* y f@ fdup f* f+ fsqrt r f!
    | v = atan2d( y, x );                  /* True anomaly */
	y f@ x f@ fatan2 v f!
    | *lon = v + w;                        /* True solar longitude */
	v f@ w f@ f+ 
		360.0 fover f< if 360.0 f- then		| normalize to 0..360
		lon f!
	;
: sun_RA_dec ( d RA^ dec^ r^ -- )
	;

|||



double latitude = -1000.0, longitude = -1000.0;
char name[40] = "";
int TZ=-99, dst=0;
int force_dst=-1;
int year = 0;
int month = 0;
int day = 0;	// the day in question!
int dst_custom = 0;	// did we override the DST range?
int dst_jday[2] = {0,0};	// DST day range.  Need to calculate it

void printtimes(void)
{
	double sunrise, sunset, dawn, dusk, shaah, hatzot;
	int rs, civ;
	char *p = &output[0];
	
	
	rs   = __sunriset__ ( -35.0/60.0, 1);
	sunrise = rise; sunset = set;
	day++;
	__sunriset__ ( -35.0/60.0, 1);
	day--;
	//hatzot = sunset+ ((rise+24.0+(sunset<0?-sunset:sunset))/12.0) ;
	hatzot =
		rise - sunset;
	//printf ("diff in hrs=%.2f\n", hatzot);
	if (hatzot < 0)
		hatzot += 24;
	hatzot /= 2.0;
	//printf ("half: %.2f\n", hatzot);
	hatzot += sunset;

	
	//printf("debug: sunset=%.2f, rise=%.2f, hatzot=%.2f\n",
	//	sunset,rise,hatzot);
		
	if (hatzot >= 24.0)
		hatzot -= 24.0;
	shaah = (((sunset<0)?24:0) +sunset - sunrise) / 12.0;
	
	// civil_twilight at 9 degrees declination
	civ   = __sunriset__ (  -7.0, 0);

#if 0
	switch( rs )
	{
		case +1:
			myputs( "Sun above horizon" );
			break;
		case -1:
			myputs( "Sun below horizon" );
			break;
	}

	switch( civ )
	{
		case +1:
			myputs( "Never darker than civil twilight\n" );
			break;
		case -1:
			myputs( "Never as bright as civil twilight\n" );
			break;
	}
#endif
	
	// output the date:
	p = printint(month, p);
	*p++ = '/';
	p = printint(day, p);
	*p++ = '/';
	p = printint4(year, p);

	// space
	*p++ = ' ';
	// dawn
	p = hhmm(rise, p);		*p++ = ' ';
	// sunrise
	p = hhmm(sunrise, p);   *p++ = ' ';
	// shema
	p = hhmm(sunrise + (shaah*3), p); *p++ =  ' ';
	// tefilah
	p = hhmm(sunrise + (shaah*4), p); *p++ = ' '; *p++ = ' ';
	// m:ged
	p = hhmm(sunrise + (shaah*6.5), p); *p++ = ' ';
	// m:ket
	p = hhmm(sunrise + (shaah*9.5), p); *p++ = ' ';
	// m:plg
	p = hhmm(sunrise + (shaah*10.75), p); *p++ = ' '; *p++ = ' ';
	// sunset
	p = hhmm(sunset, p); *p++ = ' ';
	// night
	p = hhmm(set, p); *p++ = ' ';
	// midnight
	p = hhmm(hatzot, p); *p++ = ' ';

	// sign off
	*p = '\0';
	myputs(output);
	
}

int city,num,total;

void parsedate(char *arg, int *yy, int *mm, int *dd)
{
	char temp[20];
	char *p, *pp;
	int first, second, third;
	
	strncpy(temp, arg, 19);
	temp[19] = '\0';
	
	// format might be mm/dd/yy, or it might be mm/dd (yy implied)
	first = second = third = 0;

	// find first slash;
	p = pp = &temp[0];
	while (*p && *p != '/')
		++p;

	// convert first num:
	first = atoi(pp);

	// get second number
	pp = ++p;
	while (*p && *p != '/')
		++p;
	if (*p)	// not last number
	{
		// parse last number
		third = atoi(p+1);
	}
	second = atoi(pp);

	*mm = first;
	*dd = second;
	if (third) *yy = third;
}

void onearg(char *arg)
{
	if (arg[1] == '/' ||  arg[2] == '/')
	{
		/* */
		parsedate(arg, &year, &month, &day);

	}
	else if (num = atoi(arg))
	{
		total = num;
	}
	else if (*arg== '-')
	{
		// an argument.  -tz sets tz correction
		++arg;
		if (*arg == 't')
		{
			++arg;
			
			if (*arg == '+')
				force_dst = 1;
			else if (*arg == '-')
				force_dst = 0;
		}
		if (*arg == 'd' || *arg == 'D')
		{
			// dst starts or ends:
			int y,m,d;
			parsedate(arg+1, &y, &m, &d);
			dst_jday[*arg == 'd' ? 0 : 1] = dst_jday[0] = mdy_yday(m,d,y);
			++dst_custom;
		}
		if (*arg == 'l' || *arg == 'L')
		{
			// new latitude/longitude
			int deg, min;
			char *p;
			
			deg = atoi(arg+1);
			min = 0;
			p = arg;
			while (*p && *p != ':')
				++p;
			if (*p == ':')
			{
				min =  atoi(p+1);
			}
			if (*arg == 'l')
				latitude = DEGTODEC(deg, min);
			else
				longitude = -DEGTODEC(deg,min);
		}
		if (*arg == 'z')
		{
			TZ = atoi(arg+1);
		}
		if (*arg == 'n')
		{
			// new place name
			strncpy(name, arg+1, 39);
		}
		if (*arg == 'h' || *arg == '?')
		{
			myputs("zmanim [nn] [place] [-t{-+}]");
			myputs("see docs for details");
			exit(0);
		}
	}
	else
	{
		city = findcity(arg);
	}
}

void adjust_year(int *yday, int * yy)
{
	int leap = isleap(*yy);
	if (*yday > 365 + leap)
	{
		*yy +=  1;
		*yday -= 365+leap;
		calc_dst();
	}
}

int
main(int argc, char **argv)
{
    int    rs, civ, naut, astr, ix;
	time_t now;
	struct tm *ltime;
	FILE *ini;

	int yy,mm,dd, jday, dw;

	/* process the args */
	total = 5;
	city = 0;	// default value
	time(&now);
	// set up default
	ltime = localtime(&now);
	year = ltime->tm_year+1900;
	month = ltime->tm_mon+1;
	day = ltime->tm_mday;
	calc_dst();

	/* get our ini file if it exists */
#ifdef linux
	ini = fopen("~/.zmanim", "rt");
#else
	{
	char file[256], *p;
	strcpy(file, argv[0]);
	p = file + strlen(file) - 1;
	while (p >= &file[0])
	{
		if (*p == '.')
			break;
		--p;
	}
	if (*p == '.')
	{
		strcpy(p, ".ini");
	}
	else
		strcat(file, ".ini");
	ini = fopen(file, "rt");
	}
#endif
	if (ini != NULL)
	{
		char buf[256];
		while (fgets(buf, 255, ini) != NULL)
		{
			char *p = buf + strlen(buf) - 1;
			while (p >= buf && (*p == '\r' || *p == '\n' || *p == ' ' || *p == '\t'))
				--p;

			*(p+1)='\0';
			p = buf;
			while (*p && (*p == ' ' || *p == '\t'))
				++p;
			onearg(p);
		}
		fclose(ini);
	}
	if (argc >= 1)
		while (*++argv)
		{
			onearg(*argv);
		}
	citydata(city);

	strcpy(output, "Luach z'manim halachi'im for ");
	strcat(output, name);
	myputs (output);

	myputs ("date        dawn sunup shema tfila  m:ged m:ket m:plg  sundn night hatzt");

	now = jday = mdy_yday(month, day, year);
	set_dst(jday);
	
	printtimes();
	// skip to next Friday
	// 0 is sunday, so Friday is 5
	dw = dow(year,month,day);
	while ((dw % 7) != 5)
	{
		++dw;
		++jday;
	}
	if (now == jday)
		jday += 7;
	now = jday;

	// print luah for up to 'total' weeks.
	if (total <= 0)
		total = 5;
	
	for (ix = 1; ix < total; ix++)
	{
		adjust_year((int *)&now, &year);
		yday_md(now, year, &day, &month );
		set_dst(now);
		printtimes();
		now += 7;
	}
	return 0;
}


/* The "workhorse" function for sun rise/set times */

int __sunriset__( double altit, int upper_limb)
/***************************************************************************/
/* Note: year,month,date = calendar date, 1801-2099 only.             */
/*       Eastern longitude positive, Western longitude negative       */
/*       Northern latitude positive, Southern latitude negative       */
/*       The longitude value IS critical in this function!            */
/*       altit = the altitude which the Sun should cross              */
/*               Set to -35/60 degrees for rise/set, -6 degrees       */
/*               for civil, -12 degrees for nautical and -18          */
/*               degrees for astronomical twilight.                   */
/*         upper_limb: non-zero -> upper limb, zero -> center         */
/*               Set to non-zero (e.g. 1) when computing rise/set     */
/*               times, and to zero when computing start/end of       */
/*               twilight.                                            */
/*        *rise = where to store the rise time                        */
/*        *set  = where to store the set  time                        */
/*                Both times are relative to the specified altitude,  */
/*                and thus this function can be used to compute       */
/*                various twilight times, as well as rise/set times   */
/* Return value:  0 = sun rises/sets this day, times stored at        */
/*                    *trise and *tset.                               */
/*               +1 = sun above the specified "horizon" 24 hours.     */
/*                    *trise set to time when the sun is at south,    */
/*                    minus 12 hours while *tset is set to the south  */
/*                    time plus 12 hours. "Day" length = 24 hours     */
/*               -1 = sun is below the specified "horizon" 24 hours   */
/*                    "Day" length = 0 hours, *trise and *tset are    */
/*                    both set to the time when the sun is at south.  */
/*                                                                    */
/**********************************************************************/
{
      double julian_2000_d,
	  sr,         /* Solar distance, astronomical units */
      sRA,        /* Sun's Right Ascension */
      sdec,       /* Sun's declination */
      sradius,    /* Sun's apparent radius */
      t,          /* Diurnal arc */
      tsouth,     /* Time when Sun is at south */
      sidtime;    /* Local sidereal time */

      int rc = 0; /* Return cde from function - usually 0 */
	  julian_2000_d = julian2k(year,month,day) + 0.5 - longitude/360.0;


      /* Compute local sidereal time of this moment */
      sidtime = revolution( GMST0(julian_2000_d) + 180.0 + longitude );

      /* Compute Sun's RA + Decl at this moment */
      sun_RA_dec( julian_2000_d, &sRA, &sdec, &sr );

      /* Compute time when Sun is at south - in hours UT */
      tsouth = 12.0 - rev180(sidtime - sRA)/15.0;

      /* Compute the Sun's apparent radius, degrees */
      sradius = 0.2666 / sr;

      /* Do correction to upper limb, if necessary */
      if ( upper_limb )
            altit -= sradius;

      /* Compute the diurnal arc that the Sun traverses to reach */
      /* the specified altitude altit: */
      {
            double cost;
            cost = ( sind(altit) - sind(latitude) * sind(sdec) ) /
                  ( cosd(latitude) * cosd(sdec) );
            if ( cost >= 1.0 )
                  rc = -1, t = 0.0;       /* Sun always below altit */
            else if ( cost <= -1.0 )
                  rc = +1, t = 12.0;      /* Sun always above altit */
            else
                  t = acosd(cost)/15.0;   /* The diurnal arc, hours */
      }

      /* Store rise and set times - in hours UT */
      rise = tsouth - t ;
      set  = tsouth + t ;

      return rc;
}  /* __sunriset__ */



/* The "workhorse" function */


/* This function computes the Sun's position at any instant */

void sunpos( double d, double *lon, double *r )
/******************************************************/
/* Computes the Sun's ecliptic longitude and distance */
/* at an instant given in d, number of days since     */
/* 2000 Jan 0.0.  The Sun's ecliptic latitude is not  */
/* computed, since it's always very near 0.           */
/******************************************************/
{
      double M,         /* Mean anomaly of the Sun */
             w,         /* Mean longitude of perihelion */
                        /* Note: Sun's mean longitude = M + w */
             e,         /* Eccentricity of Earth's orbit */
             E,         /* Eccentric anomaly */
             x, y,      /* x, y coordinates in orbit */
             v;         /* True anomaly */

      /* Compute mean elements */
      M = revolution( 356.0470 + 0.9856002585 * d );
      w = 282.9404 + 4.70935E-5 * d;
      e = 0.016709 - 1.151E-9 * d;

      /* Compute true longitude and radius vector */
      E = M + e * RADEG * sind(M) * ( 1.0 + e * cosd(M) );
		x = cosd(E) - e;
      y = sqrt( 1.0 - e*e ) * sind(E);
      *r = sqrt( x*x + y*y );              /* Solar distance */
      v = atan2d( y, x );                  /* True anomaly */
      *lon = v + w;                        /* True solar longitude */
      if ( *lon >= 360.0 )
            *lon -= 360.0;                   /* Make it 0..360 degrees */
}

void sun_RA_dec( double d, double *RA, double *dec, double *r )
{
      double lon, obl_ecl, x, y, z;

      /* Compute Sun's ecliptical coordinates */
      sunpos( d, &lon, r );

      /* Compute ecliptic rectangular coordinates (z=0) */
      x = *r * cosd(lon);
      y = *r * sind(lon);

      /* Compute obliquity of ecliptic (inclination of Earth's axis) */
      obl_ecl = 23.4393 - 3.563E-7 * d;

      /* Convert to equatorial rectangular coordinates - x is unchanged */
      z = y * sind(obl_ecl);
      y = y * cosd(obl_ecl);

      /* Convert to spherical coordinates */
      *RA = atan2d( y, x );
      *dec = atan2d( z, sqrt(x*x + y*y) );

}  /* sun_RA_dec */


/******************************************************************/
/* This function reduces any angle to within the first revolution */
/* by subtracting or adding even multiples of 360.0 until the     */
/* result is >= 0.0 and < 360.0                                   */
/******************************************************************/

#define INV360    ( 1.0 / 360.0 )

double revolution( double x )
/*****************************************/
/* Reduce angle to within 0..360 degrees */
/*****************************************/
{
      return( x - 360.0 * floor( x * INV360 ) );
}  /* revolution */

double rev180( double x )
/*********************************************/
/* Reduce angle to within +180..+180 degrees */
/*********************************************/
{
      return( x - 360.0 * floor( x * INV360 + 0.5 ) );
}  /* revolution */


/*******************************************************************/
/* This function computes GMST0, the Greenwich Mean Sidereal Time  */
/* at 0h UT (i.e. the sidereal time at the Greenwhich meridian at  */
/* 0h UT).  GMST is then the sidereal time at Greenwich at any     */
/* time of the day.  I've generalized GMST0 as well, and define it */
/* as:  GMST0 = GMST - UT  --  this allows GMST0 to be computed at */
/* other times than 0h UT as well.  While this sounds somewhat     */
/* contradictory, it is very practical:  instead of computing      */
/* GMST like:                                                      */
/*                                                                 */
/*  GMST = (GMST0) + UT * (366.2422/365.2422)                      */
/*                                                                 */
/* where (GMST0) is the GMST last time UT was 0 hours, one simply  */
/* computes:                                                       */
/*                                                                 */
/*  GMST = GMST0 + UT                                              */
/*                                                                 */
/* where GMST0 is the GMST "at 0h UT" but at the current moment!   */
/* Defined in this way, GMST0 will increase with about 4 min a     */
/* day.  It also happens that GMST0 (in degrees, 1 hr = 15 degr)   */
/* is equal to the Sun's mean longitude plus/minus 180 degrees!    */
/* (if we neglect aberration, which amounts to 20 seconds of arc   */
/* or 1.33 seconds of time)                                        */
/*                                                                 */
/*******************************************************************/
///
double GMST0( double d )
{
      double sidtim0;
      /* Sidtime at 0h UT = L (Sun's mean longitude) + 180.0 degr  */
      /* L = M + w, as defined in sunpos().  Since I'm too lazy to */
      /* add these numbers, I'll let the C compiler do it for me.  */
      /* Any decent C compiler will add the constants at compile   */
      /* time, imposing no runtime or code overhead.               */
      sidtim0 = revolution( ( 180.0 + 356.0470 + 282.9404 ) +
                          ( 0.9856002585 + 4.70935E-5 ) * d );
      return sidtim0;
}  /* GMST0 */
typedef struct
{
   char *name;
   short latitudedeg, latitudemin, longitudedeg, longitudemin;
   int TZ;
}
city_t;

#define DEGTODEC(dec,m) (dec + m/60.0)

//int mdays[12] =    {31,28,31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
int mday_tot[12] = {0, 31,59, 90,120,151,181,212,243,273,304,334};
int mday_tot_leap[12] = {0, 31,60, 91,121,152,182,213,244,274,305,335};

int isleap(int yy)
{
	int mod = yy % 100;
	return (yy % 4 == 0) && !(mod == 100 || mod == 200 || mod == 300);
}

int mdy_yday(int mm, int dd, int yy)
{
	return (isleap(yy)? mday_tot_leap[mm-1] : mday_tot[mm-1]) + dd;
}

//pass in yday and yy, return dd and mm.
void yday_md(int yday, int yy, int *dd, int *mm)
{
	int leap;
	
	leap = isleap(yy);  

	for (*mm=1; *mm<12; (*mm)++)
	{
		if ((leap ? mday_tot_leap[*mm] : mday_tot[*mm]) >= yday)
			break;
	}

	// *mm is the month; get the day of the month directly
	*dd = yday - (leap?mday_tot_leap[*mm-1]:mday_tot[*mm-1]);
}
