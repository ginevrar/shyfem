!
! $Id: subwaves.f,v 1.1 2006/10/18 15:35:13 georg Exp $
!
! waves subroutines
!
! revision log :
!
! 18.10.2006    ccf     integrated into main tree
! 19.06.2008    aac&ccf udate to 3D version
! 16.04.2009	ccf	update to new WWMII-2 version, both 2D and 3D
! 18.02.2011	ggu	compiler warnings/errors adjusted
! 25.10.2013	ccf	upgrade compatibility with WWMIII
! 04.11.2014	ccf	rewritten
! 21.01.2015	ggu	computing fetch for geographical coordinates (bug fix)
! 10.02.2015	ggu	randomixe change of coordinates if on node (bug fix)
! 10.03.2016	ggu	in parametric wave module fix segfault (allocatable)
! 15.04.2016	ggu	parametric wave module cleaned
! 12.04.2017	ggu	routines integrated to compute bottom stress, new module
! 01.02.2019	ggu	rbug fix in parwaves: do not compute H/P for wind == 0
!
!**************************************************************
c DOCS  START   S_wave
c
c SHYFEM could be coupled with the spectral wind wave unstructured
c model WWMIII or computes wave characteristics using empirical
c prediction equations.
c
c This empirical wave module is used to calculate the wave height 
c and period from wind speed, fetch and depth using the EMPIRICAL 
c PREDICTION EQUATIONS FOR SHALLOW WATER \cite{shoreprot:84}.
c
c WWMIII is not provided in the SHYFEM distribution.
c The coupling of SHYFEM with WWMIII is done through the FIFO PIPE 
c mechanism. The numerical mesh need to be converted to the GR3 
c format using the bas2wwm program. WWMIII needs its own input 
c parameter file (wwminput.nml). The use of the coupled SHYFEM-WWMIII
c model require additional software which is not described here.
c
c The wave module writes in the WAV file the following output:
c \begin{itemize}
c \item significant wave height [m], variable 231
c \item mean wave period [s], variable 232
c \item mean wave direction [deg], variable 233
c \end{itemize}
c
c The time step and start time for writing to file WAV 
c are defined by the parameters |idtwav| and |itmwav| in the |waves|
c section. These parameter are the same used for writting tracer
c concentration, salinity and water temperature. If |idtwav| is not
c defined, then the wave module does not write any results. The wave 
c results can be plotted using |plots -wav|.
c
c In case of SHYFEM-WWMIII coupling several variables are exchanged 
c between the two models:
c \begin{itemize}
c \item SHYFEM sends to WWMIII:
c  \begin{itemize}
c   \item surface velocities
c   \item water level
c   \item bathymetry and number of vertical layers
c   \item 3D layer depths
c   \item wind components$^{**}$
c  \end{itemize}
c \item SHYFEM reads from WWMIII:
c  \begin{itemize}
c   \item gradient of the radiation stresses
c   \item significant wave height
c   \item mean period
c   \item significant wave direction
c   \item wave supported stress
c   \item peak period
c   \item wave length
c   \item orbital velocity
c   \item stokes velocities
c   \item wind drag coefficient
c   \item wave pressure
c   \item wave dissipation
c   \item wind components$^{**}$
c \end{itemize}
c \end{itemize}
c
c $^{**}$Wind could be either read from SHYFEM or WWMIII, see parameter 
c |iwave| in Appendix C.
c For more information about WWMIII and its couling with SHYFEM please refer
c to Roland et al. \cite{roland:coupled09} and Ferrarin et al. 
c \cite{ferrarin:morpho08}.
c DOCS  END


c**************************************************************

        subroutine init_wave

! initialize arrays and open pipes in case of coupling with WWM

	use mod_waves

	implicit none

	integer itdrag		!drag coefficient type
	real getpar		!get parameter function
	integer k,ie,l
	integer nvar
	integer id
        logical has_output_d

!-------------------------------------------------------------
! initialize wave arrays
!-------------------------------------------------------------

	wavefx = 0.
	wavefy = 0.

        waveh = 0.
        wavep = 0.
        wavepp = 0.
        waved = 0.
        waveov = 0.

!-------------------------------------------------------------
! find out what to do
!-------------------------------------------------------------

	idcoup = 0

        iwave = nint(getpar('iwave'))
        itdrag = nint(getpar('itdrag'))

	if (itdrag .eq. 3 .and. iwave .lt. 2) then
	  write(6,*) 'Erroneous value for itdrag = ',itdrag
	  write(6,*) 'Use itdrag = 3 only if coupling with WWMIII'
	  stop 'error stop init_wwm: itdrag'
	end if

        if( iwave .eq. 2 .or. iwave .eq. 3 ) then
	  iwwm = 1	!wind from SHYFEM
	elseif ( iwave .eq. 4 .or. iwave .eq. 5 ) then
	  iwwm = 2	!wind from WWM
	else
	  iwwm = 0	!no SHYFEM-WWM coupling
	end if

        if( iwwm .le. 0 ) return

!-------------------------------------------------------------
! open pipe files
!-------------------------------------------------------------
       
	write(*,*)'SHYFEM opening pipe file for WWM'
 
        open(120,file='p_velx.dat',form='unformatted')
        open(121,file='p_vely.dat',form='unformatted')
        open(122,file='p_lev.dat',form='unformatted')
        open(123,file='p_bot.dat',form='unformatted')
        open(126,file='p_zeta3d.dat',form='unformatted')

        open(101,file='p_stressx.dat',form='unformatted')
        open(102,file='p_stressy.dat',form='unformatted')
        open(142,file='p_stresxy.dat',form='unformatted')
        open(103,file='p_waveh.dat',form='unformatted')
        open(104,file='p_wavet.dat',form='unformatted')
        open(105,file='p_waved.dat',form='unformatted')
        open(106,file='p_wtauw.dat',form='unformatted')
        open(107,file='p_wavetp.dat',form='unformatted')
        open(108,file='p_wavewl.dat',form='unformatted')
        open(109,file='p_orbit.dat',form='unformatted')
        open(110,file='p_stokesx.dat',form='unformatted')
        open(111,file='p_stokesy.dat',form='unformatted')
        open(114,file='p_cd.dat',form='unformatted')
        open(115,file='p_jpress.dat',form='unformatted')
        open(116,file='p_wdiss.dat',form='unformatted')

	if (iwwm .eq. 1) then
          open(124,file='p_windx.dat',form='unformatted')
          open(125,file='p_windy.dat',form='unformatted')
	else
          open(124,file='p_windx.dat',form='unformatted')
          open(125,file='p_windy.dat',form='unformatted')
	end if

!-------------------------------------------------------------
! set coupling time step 
!-------------------------------------------------------------

        call convert_time('dtwave',idcoup)

!-------------------------------------------------------------
! Initialize output
!-------------------------------------------------------------

	nvar = 3
        call init_output_d('itmwav','idtwav',da_wav)
        if( has_output_d(da_wav) ) then
	  call shyfem_init_scalar_file('wave',nvar,.true.,id)
	  da_wav(4) = id
        end if

!-------------------------------------------------------------
! exchange data on the first time step
!-------------------------------------------------------------

	call write_wwm
	call read_wwm
	call write_wwm

        write(6,*) 'SHYFEM-WWMIII wave model has been initialized'
 	!call getwwmbound

!-------------------------------------------------------------
! end of routine
!-------------------------------------------------------------
        
	end

!**************************************************************

	subroutine read_wwm

! reads from PIPE

	use mod_meteo
	use mod_waves
	use mod_roughness
	use levels, only : nlvdi,nlv
	use basin, only : nkn,nel,ngr,mbw

        implicit none

c common
	include 'param.h'
	include 'pkonst.h'

c local
        double precision, allocatable :: stokesx(:,:)	!stokes velocity x
        double precision, allocatable :: stokesy(:,:)	!stokes velocity y
        real, allocatable	      :: wavejb(:)	!wave pressure
        real, allocatable	      :: wtauw(:)    	!wave supported stress
        real, allocatable	      :: wavewl(:)     	!wave lenght
        real, allocatable	      :: wavedi(:)     	!wave dissipation
	real, allocatable	      :: SXX3D(:,:)	!radiation stress xx
	real, allocatable	      :: SYY3D(:,:)	!radiation stress yy
	real, allocatable	      :: SXY3D(:,:)	!radiation stress xy

        integer k,l, ie
	real wtau,taux,tauy		!wave and wind stresses
        real s,d			!speed and direction
        real pi,deg2rad
        parameter ( pi=3.14159265358979323846, deg2rad = pi/180. )
	double precision tmpval
	integer itdrag
	integer it
	logical bstress
	logical bwind
	save bwind
	real wfact,wspeed
	save wfact
        real getpar
        logical next_output_d
	integer id
	double precision dtime
        integer icall           	!initialization parameter                        
        save icall
        data icall /0/
	real tramp,alpha
	save tramp

        if (iwwm .le. 0 ) return

        allocate(stokesx(nlv,nkn))
        allocate(stokesy(nlv,nkn))
        allocate(wavejb(nkn))
        allocate(wtauw(nkn))
        allocate(wavewl(nkn))   
        allocate(wavedi(nkn))    
	allocate(SXX3D(nlv,nkn))
	allocate(SYY3D(nlv,nkn))
	allocate(SXY3D(nlv,nkn))

	bstress = .false.			!compute and write bottom stress

!       -----------------------------------------------
!       Opens output file for waves
!       -----------------------------------------------

        if( icall .eq. 0 ) then

          itdrag = nint(getpar('itdrag'))
	  bwind = itdrag .eq. 3		!use wave dependend drag coeff

	  tramp = 86400.
	  tramp = 0.
	  wfact = 1. / rowass
	  SXX3D = 0.
	  SXY3D = 0.
	  SYY3D = 0.
          icall = 1
        end if

!       -----------------------------------------------
!       Same time step, do read
!       -----------------------------------------------

	wtauw = 0.

	call get_act_dtime(dtime)

	it = dtime
        if (mod(it,idcoup) .eq. 0 ) then
 
!         -----------------------------------------------
!         Reads stress and wave characteristics
!         -----------------------------------------------

  	  if (iwwm .eq. 1) then 	!do not read wind from WWM

            do k = 1,nkn

	      do l = 1,nlv 
                 read(101) tmpval
		 SXX3D(l,k) = tmpval
                 read(102) tmpval
		 SYY3D(l,k) = tmpval
                 read(142) tmpval
		 SXY3D(l,k) = tmpval
	      end do

              read(103) tmpval
	      waveh(k) = tmpval
              read(104) tmpval
	      wavep(k) = tmpval
              read(105) tmpval
	      waved(k) = tmpval
              read(106) tmpval
	      wtauw(k) = tmpval
              read(107) tmpval
	      wavepp(k) = tmpval
              read(108) tmpval
	      wavewl(k) = tmpval
              read(109) tmpval
	      waveov(k) = tmpval
              read(110) (stokesx(l,k),l=1,nlv)
              read(111) (stokesy(l,k),l=1,nlv)
              read(114) tmpval
	      if ( bwind ) windcd(k) = tmpval
              read(115) tmpval
	      wavejb(k) = tmpval
              read(116) tmpval
	      wavedi(k) = tmpval

            end do

	  elseif (iwwm .eq. 2) then	!read wind from WWM

            do k = 1,nkn

	      do l = 1,nlv 
                 read(101) tmpval
		 SXX3D(l,k) = tmpval
                 read(102) tmpval
		 SYY3D(l,k) = tmpval
                 read(142) tmpval
		 SXY3D(l,k) = tmpval
	      end do

              read(103) tmpval
	      waveh(k) = tmpval
              read(104) tmpval
	      wavep(k) = tmpval
              read(105) tmpval
	      waved(k) = tmpval
              read(106) tmpval
	      wtauw(k) = tmpval
              read(107) tmpval
	      wavepp(k) = tmpval
              read(108) tmpval
	      wavewl(k) = tmpval
              read(109) tmpval
	      waveov(k) = tmpval
              read(110) (stokesx(l,k),l=1,nlv)
              read(111) (stokesy(l,k),l=1,nlv)
              read(114) tmpval
	      windcd(k) = tmpval
              read(115) tmpval
	      wavejb(k) = tmpval
              read(116) tmpval
	      wavedi(k) = tmpval
              read(124) tmpval
	      wxv(k) = tmpval
              read(125) tmpval
	      wyv(k) = tmpval
              ppv(k) = 0.

!             -----------------------------------------------
!             Transforms wind speed to stress in case of iwwm .eq. 2 
!  	      and use wave induced CD
!             -----------------------------------------------
	      wspeed = sqrt( wxv(k)**2 + wyv(k)**2 )
              tauxnv(k) = wfact * windcd(k) * wspeed * wxv(k)
              tauynv(k) = wfact * windcd(k) * wspeed * wyv(k)

            end do

	  end if

          write(*,*) 'SHYFEM read stress and wave ',it

!         -----------------------------------------------
!         Compute surface roughness z0s = 0.5*Hs
!         -----------------------------------------------

          do k = 1,nkn
	    z0sk(k) = 0.5 * waveh(k)
          end do

!         -----------------------------------------------
!         Computes wave induced forces
!         -----------------------------------------------

	  if (iwave .eq. 2 .or. iwave .eq. 4) then

!           -----------------------------------------------
!           Radiation stress formulation
!           -----------------------------------------------

	    call diffxy(SXX3D,SYY3D,SXY3D,wavefx,wavefy)

	  elseif (iwave .eq. 3 .or. iwave .eq. 5) then
!           -----------------------------------------------
!           Vortex force formulation and substract wave-supported
!	    stress from wind stress (still to be implemented)
!           -----------------------------------------------

	    call wave_vortex(stokesx,stokesy,wavejb,wavefx,wavefy)

            do k = 1,nkn
	      wtau = wtauw(k)
              taux = tauxnv(k)
              tauy = tauynv(k)
	      s = sqrt(taux**2 + tauy**2)
	      if (s .gt. wtau) then
	        d = atan2(tauy,taux)
	        tauxnv(k) = taux - wtau * cos(d)
	        tauynv(k) = tauy - wtau * sin(d)
	      end if
            end do

	  end if

!         -----------------------------------------------
!         simulate smooth initial forcing
!	  useful for test cases
!         -----------------------------------------------

	  alpha = 1.
          if( tramp .gt. 0. ) then
            call get_passed_dtime(dtime)
            alpha = dtime/tramp
            if( alpha .gt. 1. ) alpha = 1.
	  end if
	  if( alpha /= 1. ) then
	    do ie = 1,nel
	      do l = 1,nlv
	        wavefx(l,ie) = wavefx(l,ie) * alpha
	        wavefy(l,ie) = wavefy(l,ie) * alpha
	      end do
	    end do
	  end if

        end if

!       -----------------------------------------------
!       Writes output to the file.wav 
!       -----------------------------------------------

        if( next_output_d(da_wav) ) then
	  id = nint(da_wav(4))
	  call shy_write_scalar_record(id,dtime,231,1,waveh)
	  call shy_write_scalar_record(id,dtime,232,1,wavep)
	  call shy_write_scalar_record(id,dtime,233,1,waved)
	end if

        end

!**************************************************************

        subroutine write_wwm

! write to PIPE

	use mod_meteo
	use mod_waves
	use mod_depth
	use mod_hydro
	use levels
	use basin, only : nkn,nel,ngr,mbw

        implicit none

	!include 'param.h'

	real, allocatable	:: ddl(:,:) !3D layer depth (in the middle of layer)
	real, allocatable 	:: h(:)
        integer it              !time [s]
        integer k,l,nlev,lmax
	real u,v
	double precision tempvar,dtime

        allocate(ddl(nlv,nkn))
        allocate(h(nlv))

        if (iwwm .le. 0 ) return

!       -----------------------------------------------
!       Same time step, do write
!       -----------------------------------------------

	call get_act_dtime(dtime)
	it = dtime

        if (mod(it,idcoup) .eq. 0 ) then

!         -----------------------------------------------
!         Computes 3D layer depth array
!         -----------------------------------------------

	  ddl = 0.

          do k = 1,nkn
	    call dep3dnod(k,+1,nlev,h)
            ddl(1,k) = - 0.5 * h(1)
            do l = 2,nlev
              ddl(l,k) = ddl(l-1,k) - 0.5 * (h(l) + h(l-1))
            end do
          end do

!         -----------------------------------------------
!         write velocities and water level
!         -----------------------------------------------

	  if (iwwm .eq. 1) then	! write wind to wwm

            do k = 1,nkn 
	      call getuv(1,k,u,v)
	      tempvar = DBLE(u)
              write(120) tempvar
	      flush(120)
	      tempvar = DBLE(v)
              write(121) tempvar
	      flush(121)
	      tempvar = DBLE(znv(k))
              write(122) tempvar
	      flush(122)
	      tempvar = DBLE(hkv(k))
              write(123) tempvar
	      flush(123)
              write(123) ilhkv(k)
	      flush(123)
	      tempvar = DBLE(wxv(k))
              write(124) tempvar
	      flush(124)
	      tempvar = DBLE(wyv(k))
              write(125) tempvar
	      flush(125)

              do l = 1,nlv
		tempvar = DBLE(ddl(l,k))
                write(126) tempvar
	      end do 
	      flush(126)
	    end do 

	  elseif (iwwm .eq. 2) then	! do not write wind to wwm

            do k = 1,nkn 
	      call getuv(1,k,u,v)
	      tempvar = DBLE(u)
              write(120) tempvar
	      flush(120)
	      tempvar = DBLE(v)
              write(121) tempvar
	      flush(121)
	      tempvar = DBLE(znv(k))
              write(122) tempvar
	      flush(122)
	      tempvar = DBLE(hkv(k))
              write(123) tempvar
	      flush(123)
              write(123) ilhkv(k)
	      flush(123)

              do l = 1,nlv
		tempvar = DBLE(ddl(l,k))
                write(126) tempvar
	      end do 
	      flush(126)
            end do

	  end if

          write(*,*) 'SHYFEM writes vel and water level', it
 
        end if

        end

!**************************************************************************

        subroutine getwwmbound

!routine to write boundary node file for wwm (fort.22)

	use mod_depth
	use basin

        implicit none

	integer i,knode,nn,ibc,nbc
	integer nbnds,nkbnds,kbnds

	nbc = nbnds()

        do ibc=1,nbc

	  nn = nkbnds(ibc)
	  write(26,*) nn

          do i=1,nn
	    knode = kbnds(ibc,i)
            write(26,25) knode,xgv(knode),ygv(knode),hkv(knode)
	  end do
	enddo

25	format(i10,3e14.4)

	end

!**************************************************************************
! Computes wave forcing terms according to the radiation stress formulation

        subroutine diffxy(SXX3D,SYY3D,SXY3D,wavefx,wavefy)

	use evgeom
	use levels
	use basin

        implicit none

        !include 'param.h'

        real SXX3D(nlv,nkn)       !radiation stress xx
        real SYY3D(nlv,nkn)       !radiation stress yy
        real SXY3D(nlv,nkn)       !radiation stress xy

        real wavefx(nlv,nel)      !wave forcing term x
        real wavefy(nlv,nel)      !wave forcing term y

        double precision b,c           !x and y derivated form function [1/m]
	integer k,ie,ii,l,ilevel
        real radsx,radsy

  	call nantest(nkn*nlv,SXX3D,'SXX3D')
	call nantest(nkn*nlv,SXY3D,'SXY3D')
	call nantest(nkn*nlv,SYY3D,'SYY3D')

	do ie = 1,nel
	  ilevel = ilhv(ie)
	  do l=1,ilevel
	    radsx = 0.
	    radsy = 0.
	    do ii = 1,3
	      k = nen3v(ii,ie)
              b = ev(3+ii,ie)
              c = ev(6+ii,ie)
	      radsx = radsx -(SXX3D(l,k)*b + SXY3D(l,k)*c)
	      radsy = radsy -(SXY3D(l,k)*b + SYY3D(l,k)*c)
	    end do
	  wavefx(l,ie) = -radsx
	  wavefy(l,ie) = -radsy
          end do
	enddo

	end

!**************************************************************************
! Computes wave forcing terms according to the vortex force formulation

	subroutine wave_vortex(stokesx,stokesy,wavejb,wavefx,wavefy)

	use mod_internal
	use mod_depth
	use mod_layer_thickness
	use mod_hydro_vel
	use evgeom
	use levels
	use basin

        implicit none

c parameters
        !include 'param.h'

c arguments
        double precision stokesx(nlv,nkn) !x stokes velocity
        double precision stokesy(nlv,nkn) !y stokes velocity
        real wavejb(nkn)             	!wave pressure
        real wavefx(nlv,nel)		!x wave forcing term
	real wavefy(nlv,nel)		!y wave forcing term

c common
	include 'pkonst.h'

c local
        real, allocatable :: stokesz(:,:)	!z stokes velocity on node k
	real, allocatable :: hk(:)		!layer tickness on nodes
	real, allocatable :: stxe(:,:)		!x stokes transport on elements
	real, allocatable :: stye(:,:)		!y stokes transport on elements
        real, allocatable :: saux1(:,:)
        real, allocatable :: saux2(:,:)
	real, allocatable :: stokesze(:,:)	!z stokes velocity on elements
	real, allocatable :: uaux(:)
	real, allocatable :: vaux(:)
	integer k,ie,ii,l,ilevel
	real f				!Coriolis parameter on elements
	real h				!layer thickness
	real u,v			!velocities at level l and elements
	real stxk, styk			!stokes transport on nodes
	real auxx, auxy			!auxiliary variables
	real jbk			!integrated wave perssure term
        double precision b,c		!x and y derivated form function [1/m]
	real wavesx,wavesy
	real wuz,wvz			!z vortex force
	real sz,sz1

!       -----------------------------------------------
!       Initialization
!       -----------------------------------------------

	wavefx = 0.d0
	wavefy = 0.d0

        allocate(stokesz(nlv,nkn))
	allocate(hk(nlv))
	allocate(stxe(nlv,nel))
	allocate(stye(nlv,nel))
        allocate(saux1(nlv,nkn))
        allocate(saux2(nlv,nkn))
	allocate(stokesze(0:nlv,nel))
	allocate(uaux(0:nlv+1))
	allocate(vaux(0:nlv+1))

        stokesze = 0.
	stxe = 0.
	stye = 0.

!       -----------------------------------------------
!       Computes wave forcing terms due to horizontal stokes
!	velocities and wave pressure head
!       -----------------------------------------------

        do ie = 1,nel
          ilevel = ilhv(ie)
	  f = fcorv(ie)
          do l = 1,ilevel
            wavesx = 0.
            wavesy = 0.
	    auxx = 0.
	    auxy = 0.
            h = hdenv(l,ie)
	    u = ulnv(l,ie)
	    v = vlnv(l,ie)
            do ii = 1,3
              k = nen3v(ii,ie)
	      h = hdknv(l,k)
              b = ev(3+ii,ie)
              c = ev(6+ii,ie)
	      stxk = stokesx(l,k) * h
	      styk = stokesy(l,k) * h
	      auxx = auxx + stxk
	      auxy = auxy + styk
              jbk = wavejb(k) * h * grav / 3.	!???? is it correct to divide by 3?

              wavesx = wavesx - (u*b*styk - v*c*styk) + b*jbk
              wavesy = wavesy + (u*b*stxk - v*c*stxk) + c*jbk

	      !Dutour Sikiric
              !wavesx = wavesx - (u*b*stxk + v*b*styk) + b*jbk
              !wavesy = wavesy - (u*c*stxk + v*c*styk) + c*jbk

            end do
	    stxe(l,ie) = auxx / 3.
	    stye(l,ie) = auxy / 3.

            wavefx(l,ie) = wavesx - f*stye(l,ie)
            wavefy(l,ie) = wavesy + f*stxe(l,ie)
          end do
        enddo
!       -----------------------------------------------
!       Check for nan
!       -----------------------------------------------
            
	call nantest(nel*nlv,wavefx,'WAVEFX')
	call nantest(nel*nlv,wavefy,'WAVEFy')

!       -----------------------------------------------
!       Computes vertical stokes velocity
!       -----------------------------------------------

	call stokes_vv(saux1,saux2,stxe,stye,stokesz,stokesze)

!       -----------------------------------------------
!       Computes wave forcing terms due to vertical stokes
!	velocity
!       -----------------------------------------------

        do ie = 1,nel
          ilevel = ilhv(ie)

	  do l = 1,ilevel
	    uaux(l) = ulnv(l,ie)
	    vaux(l) = vlnv(l,ie)
	  end do
	  uaux(0) = 0.
	  vaux(0) = 0.
	  uaux(ilevel+1) = 0.
	  vaux(ilevel+1) = 0.

          do l = 1,ilevel
	    sz = stokesze(l,ie)
	    sz1 = stokesze(l-1,ie)
	    wuz = 0.
	    wvz = 0.

	    if ( sz1 .lt. 0. ) then
	      wuz = wuz - sz1*uaux(l-1)
	      wvz = wvz - sz1*vaux(l-1)
	    else
	      wuz = wuz - sz1*uaux(l)
	      wvz = wvz - sz1*vaux(l)
	    end if

	    if ( sz .gt. 0. ) then
	      wuz = wuz + sz*uaux(l+1)
	      wvz = wvz + sz*vaux(l+1)
	    else
	      wuz = wuz + sz*uaux(l)
	      wvz = wvz + sz*vaux(l)
	    end if
	
            wavefx(l,ie) = wavefx(l,ie) + wuz		!check stokesz first
            wavefy(l,ie) = wavefy(l,ie) + wvz
          end do
        enddo

	end

!**************************************************************************
! Computes vertical stokes velocity

	subroutine stokes_vv(vf,va,stxe,stye,auxstz,stokesze)

	use evgeom
	use levels
	use basin

        implicit none

c parameters
        include 'param.h'
c arguments
        real vf(nlv,nkn)		!auxiliary array
        real va(nlv,nkn)		!auxiliary array
	real stxe(nlv,nel)	!x stokes transport on elements
	real stye(nlv,nel)	!y stokes transport on elements
	real auxstz(nlv,nkn) 	!z stokes velocity on node k for plot
	real stokesze(0:nlv,nel)	!z stokes velocity on elements

c local
	real, allocatable :: stokesz(:,:) 	!z stokes velocity on node k
        logical debug
        integer k,ie,ii,kk,l,lmax
        integer ilevel
        double precision b,c            !x and y derivated form function [1/m]
	real aj,ff,atop,acu
        logical is_zeta_bound,is_boundary_node

c initialize

	allocate(stokesz(0:nlv,nkn))
        vf = 0.
        va = 0.
        stokesz = 0.
	auxstz = 0.

c compute difference of velocities for each layer

        do ie=1,nel
          aj=4.*ev(10,ie)               !area of triangle / 3
          ilevel = ilhv(ie)
          do l=1,ilevel
            do ii=1,3
               kk=nen3v(ii,ie)
               b = ev(ii+3,ie)
               c = ev(ii+6,ie)
               ff = stxe(l,ie)*b + stye(l,ie)*c
               vf(l,kk) = vf(l,kk) + 3. * aj * ff
               va(l,kk) = va(l,kk) + aj
            end do
          end do
        end do

c from vel difference get absolute velocity (w_bottom = 0)
c       -> stokesz(nlv,k) is already in place !
c       -> stokesz(nlv,k) = 0 + stokesz(nlv,k)
c w of bottom of last layer must be 0 ! -> shift everything up
c stokesz(nlv,k) is always 0
c
c dividing stokesz [m**3/s] by area [vv] gives vertical velocity
c
c in vv(l,k) is the area of the upper interface: a(l) = a_i(l-1)
c =>  w(l-1) = flux(l-1) / a_i(l-1)  =>  w(l-1) = flux(l-1) / a(l)

        do k=1,nkn
          lmax = ilhkv(k)
          stokesz(lmax,k) = 0.
          debug = k .eq. 0
          do l=lmax,1,-1
            stokesz(l-1,k) = stokesz(l,k) + vf(l,k)
          end do
          stokesz(0,k) = 0.        ! ensure no flux across surface - is very small
        end do

        do k=1,nkn
          lmax = ilhkv(k)
          debug = k .eq. 0
          do l=2,lmax
            atop = va(l,k)
            if( atop .gt. 0. ) then
              stokesz(l-1,k) = stokesz(l-1,k) / atop
              if( debug ) write(6,*) k,l,atop,stokesz(l-1,k)
            end if
	    auxstz(l,k) = stokesz(l,k)
          end do
	  auxstz(lmax,k) = stokesz(lmax,k)
        end do

c set w to zero at open boundary nodes (new 14.08.1998)

        do k=1,nkn
            !if( is_zeta_bound(k) ) then
            if( is_boundary_node(k) ) then
              do l=0,nlv
                stokesz(l,k) = 0.
	        auxstz(l,k) = 0.
              end do
            end if
        end do

c-----------------------------------------------------------
c convert values to elelemts
c-----------------------------------------------------------

        do ie=1,nel
          lmax = ilhv(ie)
          do l = 1,lmax
            acu = 0.
            do ii=1,3
              k = nen3v(ii,ie)
              acu = acu + stokesz(l,k)
            end do
            stokesze(l,ie) = acu / 3.
          end do
          stokesze(0,ie) = 0.
        end do

        return
        end

c******************************************************************
c******************************************************************
c******************************************************************
c******************************************************************
c******************************************************************
c
c This routine is used to calculate the wave height and period
c from wind speed, fetch and depth using the EMPIRICAL PREDICTION
c EQUATIONS FOR SHALLOW WATER (Shore Protection Manual, 1984).
c It considers a homogeneous wind field all over the domain.
c It works only with cartesian coordinate system.
c
c notes :
c
c Hs            significant wave height
c Tm            mean period
c Hrms          rms height (Hrms = Hs/sqrt(2))
c Tp            peak period (Tm = 0.781 Tp)
c
c Tm = 11 sqrt(Hs/g)    if no info on Tm is available
c
c for sediment transport use T=Tp and Uw = sqrt(2) Urms
c
c Uw            orbital velocity
c Urms          std. dev. of orbital velocity
c
c Dispersion relation:
c
c o             omega, frequency, o = 2 pi / T
c k             wave number, k = 2 pi / L
c L             wave length
c
c o**2 = gk tanh(kh)    dispersion relation
c
c zeta = o**2 h / g
c eta = k h
c
c ==> zeta = eta tanh(eta)
c
c easy computation (better than 1 %)
c
c zeta < 1      eta = sqrt(zeta) * (1 + 0.2 * zeta)
c zeta > 1      eta = zeta( 1 + 0.2 * exp(2 - 2 * zeta)
c
c Orbital velocity:
c
c Uw = pi H / (T sinh(kh))
c
c**************************************************************

!==============================================================
	module mod_parwaves
!==============================================================

	implicit none

        real, parameter :: z0 = 5.e-4
        real, parameter :: awice = 1.	!use wave reduction due to ice cover

c --- input variable

        real, save, allocatable :: winds(:) !wind speed at 10m [m/s]
        real, save, allocatable :: windd(:) !wind direction [degree north]
        real, save, allocatable :: fet(:)   !wind fetch length [m]
        real, save, allocatable :: daf(:)   !averaged depth along the fetch [m]

c --- output variable

        real, save, allocatable :: waeh(:)	!wave height [m]
        real, save, allocatable :: waep(:)	!wave period [s]
        real, save, allocatable :: waed(:)	!wave direction (same as wind)

!==============================================================
	end module mod_parwaves
!==============================================================

        subroutine parwaves

c called for iwave == 1

	use mod_meteo
	use mod_waves
	use basin
	use mod_parwaves

        implicit none

c --- aux variable

        real, save, allocatable :: v1v(:)	!aux variable
        real, save, allocatable :: icecover(:)	!ice cover

c --- local variable

	logical debug,bstress
        real depele             !element depth function [m]
        real hbr		!limiting wave height [m]
        real dep,depe
        real gh,gx,hg
	real wis,wid
	real wmin,wmax
	real wx,wy,fice
        real auxh,auxh1,auxt,auxt1
        integer ie,icount,ii,k
	integer id,nvar,czero,hzero
	double precision dtime

        real, parameter :: g = 9.81		!gravity acceleration [m2/s]

        real ah1,ah2,ah3,eh1,eh2,eh3,eh4
        real at1,at2,at3,et1,et2,et3,et4
c------------------------------------------------------ Hurdle and Stive
c        parameter(ah1=0.25,ah2=0.6,eh1=0.75)
c        parameter(eh2=0.5,ah3=4.3e-05,eh3=1.,eh4=2.)
c        parameter(at1=8.3,at2=0.76,et1=0.375)
c        parameter(et2=1./3.,at3=4.1e-05,et3=1.,et4=3.)
c------------------------------------------------------ SPM
        parameter(ah1=0.283,ah2=0.53,eh1=3./4.)
        parameter(eh2=1.,ah3=0.00565,eh3=1./2.,eh4=1.)
        parameter(at1=7.54,at2=0.833,et1=3./8.)
        parameter(et2=1.,at3=0.0379,et3=1./3.,et4=1.)
c------------------------------------------------------

        real getpar

        logical has_output_d,next_output_d

        integer, save :: icall = 0		!initialization parameter

	debug = .true.
	debug = .false.
	bstress = .false.			!compute and write bottom stress

c ----------------------------------------------------------
c Initialization
c ----------------------------------------------------------

        if( icall .le. -1 ) return

        if( icall .eq. 0 ) then

c         --------------------------------------------------
c         Initialize state variables
c         --------------------------------------------------

          iwave = nint(getpar('iwave'))
          if( iwave .le. 0 ) icall = -1
          if( iwave .gt. 1 ) icall = -1
          if( icall .le. -1 ) return

	  allocate(waeh(nel))
	  allocate(waep(nel))
	  allocate(waed(nel))
          waeh = 0.
          waep = 0.
          waed = 0.

	  allocate(winds(nel),windd(nel))
	  allocate(fet(nel),daf(nel))
	  allocate(icecover(nkn),v1v(nkn))

c         --------------------------------------------------
c         Initialize output
c         --------------------------------------------------

	  nvar = 3
	  if( bstress ) nvar = 4

          call init_output_d('itmwav','idtwav',da_wav)
          if( has_output_d(da_wav) ) then
	    call shyfem_init_scalar_file('wave',nvar,.true.,id)
	    da_wav(4) = id
          end if

          write(6,*) 'parametric wave model initialized...'
          icall = 1
        endif

c -------------------------------------------------------------------
c normal call
c -------------------------------------------------------------------

	call get_ice_all(icecover)

c       -------------------------------------------------------------
c	get wind speed and direction
c       -------------------------------------------------------------

	do ie=1,nel
	  wx = 0.
	  wy = 0.
	  do ii=1,3
	    k = nen3v(ii,ie)
	    fice = 1. - awice*icecover(k)
	    wx = wx + fice * wxv(k)
	    wy = wy + fice * wyv(k)
	  end do
	  wx = wx / 3.
	  wy = wy / 3.
          call c2p(wx,wy,winds(ie),windd(ie))
	end do

c       -------------------------------------------------------------
c	get wind fetch (fet is fetch on elements)
c       -------------------------------------------------------------

        call fetch(windd,fet,daf)

	if( debug ) then
	  write(155,*) '----------------------------------------'
	  do ie=1,nel,nel/10
	    write(155,*) ipev(ie),fet(ie),daf(ie),winds(ie),windd(ie)
	  end do
	  ie = 1743
	  write(155,*) ipev(ie),fet(ie),daf(ie),winds(ie),windd(ie)
	  write(155,*) '----------------------------------------'
	end if

c       -------------------------------------------------------------------
c       start loop on elements
c       -------------------------------------------------------------------

        do ie = 1,nel

          icount = 1

c         -----------------------------------------------------------------
c	  get averaged depth along the fetch
c         -----------------------------------------------------------------

          dep = daf(ie)
          depe = depele(ie,+1)
          dep = depele(ie,+1)
10        continue

c         -----------------------------------------------------------------
c	  calculate wave height, period and direction
c         -----------------------------------------------------------------

	  wis = winds(ie)
	  wid = windd(ie)

c         -----------------------------------------------------------------
c	  method of SPM
c         -----------------------------------------------------------------

	  if( wis > 0. ) then
            gh = (g*dep)/(wis**2.)
            gx = (g*fet(ie))/(wis**2.)
            hg = dep / (g*wis**2.)
            auxh = ah2*gh**eh1
            auxh1 = ah2*hg**eh1
            auxt = at2*gh**et1
            auxt1 = ah2*gx**eh1

            waeh(ie) = (tanh(auxh))**eh4
            waeh(ie) = (ah3*gx**eh3) / waeh(ie)
            waeh(ie) = (tanh(waeh(ie)))**eh2
            waeh(ie) = ah1*tanh(auxh)*waeh(ie)
            waeh(ie) = waeh(ie) * wis**2 / g
          
            waep(ie) = (tanh(auxt))**et4
            waep(ie) = (at3*gx**et3) / waep(ie)
            waep(ie) = (tanh(waep(ie)))**et2
            waep(ie) = at1*tanh(auxt)*waep(ie)
            waep(ie) = waep(ie) * wis / g
	  else
	    waeh(ie) = 0.
	    waep(ie) = 0.
	  end if

c          waeh(ie) = 0.283 * tanh(0.530*(gh**(3./4.)))*
c     %            tanh((0.00565*(gx**0.5))/
c     %            (tanh(0.530*(gh**(3./4.)))))*((wis**2)/g)
c
c          waep(ie) = 7.54*tanh(0.833*(gh**(3./8.)))*
c     %            tanh((0.0379*(gx**(1./3.)))/
c     %            (tanh(0.833*(gh**(3./8.)))))*(wis/g)
c

c         -----------------------------------------------------------------
c	  method of hurdle and stive
c         -----------------------------------------------------------------

c          waeh(ie) = (tanh(auxh))**eh4
c          waeh(ie) = (ah3*gx**eh3) / waeh(ie)
c          waeh(ie) = (tanh(waeh(ie)))**eh2
c          waeh(ie) = ah1*tanh(auxh)*waeh(ie)
c          waeh(ie) = waeh(ie) * wis**2 / g
         
c          waep(ie) = (tanh(auxt1))**et4
c          waep(ie) = (at3*gx**et3) / waep(ie)
c          waep(ie) = (tanh(waep(ie)))**et2
c          waep(ie) = at1*tanh(auxt)*waep(ie)
c          waep(ie) = waep(ie) * wis / g

          waed(ie) = wid

c         -----------------------------------------------------------------
c	  limiting wave height
c         -----------------------------------------------------------------

          hbr = 0.50*depe
          if( waeh(ie).gt.hbr ) then
            if (icount.gt.1) then
              waeh(ie) = hbr
              go to 20
            end if
            dep = depe
            icount = 2
            goto 10
          end if 
20        continue

        end do

	!wmin = minval(winds)
	!wmax = maxval(winds)
	!czero = count( winds == 0. )
	!hzero = count( waeh == 0. )
	!write(6,*) 'wmin/wmax: ',wmin,wmax,czero,hzero

c       -------------------------------------------------------------------
c       copy to global values and write of results (file WAV)
c       -------------------------------------------------------------------

        call e2n2d(waeh,waveh,v1v)
        call e2n2d(waep,wavep,v1v)
        call e2n2d(waed,waved,v1v)

	if( bstress ) call simple_sedi_bottom_stress(v1v)	!FIXME

	wavepp = wavep

        if( next_output_d(da_wav) ) then
	  id = nint(da_wav(4))
	  call get_act_dtime(dtime)
	  call shy_write_scalar_record(id,dtime,231,1,waveh)
	  call shy_write_scalar_record(id,dtime,232,1,wavep)
	  call shy_write_scalar_record(id,dtime,233,1,waved)
	  if( bstress ) call shy_write_scalar_record(id,dtime,60,1,v1v)
	end if

c       -------------------------------------------------------------------
c       end of routine
c       -------------------------------------------------------------------

        end

c**************************************************************
c**************************************************************
c**************************************************************

        subroutine fetch(windd,fet,daf)

c This subroutine computes the wind fetch for each element of the
c grid given the wind direction.

	use basin, only : nkn,nel,ngr,mbw
	use coordinates

        implicit none
  
        real windd(nel)		!wind direction [degree north]
        real fet(nel)		!wind fetch length [m] (return)
        real daf(nel)		!averaged depth along the fetch [m] (return)

        real xe,ye		!element point coordinates [m]
	real fff,ddd
        real rad,wdir,wid
	double precision wddir
        integer ie,ierr
	integer iespecial
	integer icaver,icmax

        rad = 45. / atan (1.)
	iespecial = 1743
	iespecial = 0
	icaver = 0
	icmax = 0

c --- loop over elements

        do ie = 1,nel
          
          call baric_cart(ie,xe,ye)

	  wid = windd(ie)
          wdir = wid / rad		!from deg to rad

	  ierr = 0
	  if( ie == iespecial ) ierr = 1			!debug mode
	  call fetch_element(ie,xe,ye,wdir,fff,ddd,ierr)
	  icaver = icaver + ierr
	  icmax = max(icmax,ierr)

	  if( ierr .ge. 1000 ) then
	    write(6,*) 'warning: iteration exceeded: ',ie
	    ierr = 1
	    wddir = wdir
	    write(156,*) 'iterations in parametric wave model: '
	    write(156,*) 0,0
	    write(156,*) ie,wddir
	    call fetch_element(ie,xe,ye,wdir,fff,ddd,ierr)
	  end if

          fet(ie) = fff
          daf(ie) = ddd
	  
	end do

	icaver = icaver/nel

	!write(156,*) 'stats parametric wave model: ',icaver,icmax

	end

c**************************************************************

        subroutine fetch_element(ie,xein,yein,wdir,fff,ddd,ierr)

c This subroutine computes the wind fetch for element ie
c given the wind direction.

	use basin, only : nkn,nel,ngr,mbw

        implicit none
  
	integer ie		!element
	real xein,yein		!initial point
	real wdir		!wind direction
	real fff		!fetch computed (return)
	real ddd 		!average depth computed (return)
	integer ierr		!error code
				!on entry if >0 write debug information
				!on return number of iterations executed

        real xe,ye		!element point coordinates [m]
        real xnew,ynew		!new coordinates [m]
        real de			!distance between points [m]
        real depele             !element depth function [m]
        real dep		!element depth [m]
        integer iie,ii,ienew,icount,ieold
	logical bdebug

        iie = ie
        ieold = ie
	bdebug = ierr > 0
	fff = 0.
	ddd = 0.
	xe = xein
	ye = yein

c --- calculate fetch and averaged depth along the fetch

	if( bdebug ) then
	  write(156,*) '=========================='
	  write(156,*) iie
	end if

        icount = 0
	ienew = 1	!just to enter the while loop

	do while( ienew > 0 .and. icount < 1000 )
          call intersect(iie,xe,ye,wdir,ienew,xnew,ynew,ieold,bdebug)
          dep = depele(iie,+1)
          de = ((xnew-xe)**2 + (ynew-ye)**2)**0.5
          fff = fff + de
          ddd = ddd + dep*de
          icount = icount + 1
	  if( bdebug ) then
	    write(156,*) '-------------------'
	    write(156,*)  icount
	    write(156,*)  iie,ienew,ieold
	    write(156,*)  xe,ye,xnew,ynew
	    write(156,*)  de,dep,fff,ddd
	    write(156,*) '-------------------'
	  end if
          ieold = iie
          iie = ienew
          xe = xnew
          ye = ynew
	end do

        if( fff > 0. ) ddd = ddd/fff
        if(ienew.lt.0) fff = fff + 50000.	!open boundary

	if( bdebug ) then
	  write(156,*) icount,fff,ddd
	  write(156,*) '=========================='
	end if
 
	ierr = icount

	return
        end
           
c******************************************************************

        subroutine intersect(iie,x,y,wdir,ien,xn,yn,ieold,bdebug)

c this routine computes the coordinate of the intersection beetwen the
c line and one of the border line of the element

	use mod_geom
	use basin
	use coordinates

        implicit none

        integer iie		!element number
        real x,y		!start point cooridnates [m]
        real wdir		!direction to search [radians]
        integer ien		!next element number (return)
        real xn,yn		!intersection coordinates [m] (return)
	integer ieold
	logical bdebug

        real x0(3),y0(3)        !element vertices coordinates [m]
        real xg0(3),yg0(3)      !element vertices coordinates [degrees]
        real x3,y3,x4,y4	!node points coordiantes [m]
        real xi,yi		!intersection point coordinate [m]
	real xf,yf		!far away point
	real d			!distance
	real rx,ry
	double precision a(3),b(3),c(3)
        integer iint,i,ii,iii
        integer ienew

        integer segsegint	!intersection function

	d = 5000000.
        xf = x + d*sin(wdir)
        yf = y + d*cos(wdir)

        ien = 0
	xn = 0.
	yn = 0.
        call getexy_cart(iie,x0,y0)
	if( bdebug ) then
	  write(156,*) '.............'
	  write(156,*) iie
	  write(156,*) x0
	  write(156,*) y0
	  write(156,*) x,y,xf,yf
	end if
 
        do i = 1,3

          ii=mod(i,3)+1
          iii=mod(ii,3)+1

          x3=x0(ii)
          y3=y0(ii)
          x4=x0(iii)
          y4=y0(iii)

2         continue
          iint = segsegint(x,y,xf,yf,x3,y3,x4,y4,xi,yi)

          ienew = ieltv(i,iie)
	
	  if( bdebug ) then
	    write(156,*) i,iint,iie,ienew,ieold
	  end if

          if(iint.gt.0.and.ienew.ne.ieold)then	!intersection
            if(iint.eq.3)then	 		!intersection with node
              !x = x + 1.
              !y = y + 1.
	      call random_number(rx)
	      call random_number(ry)
              x = x + 10.*(rx-0.5)
              y = y + 10.*(ry-0.5)
	      if( bdebug ) then
	  	write(156,*) 9,0,0,0,0
		write(156,*) 'warning: node intersection: ',i,x,y
	      end if
              go to 2
            else
	      if( bdebug .and. ien .gt. 0 ) then
	  	write(156,*) 9,0,0,0,0
		write(156,*) 'warning: ien already set: ',ien,xn,yn
	      end if
              xn = xi
              yn = yi
              ien = ienew
            end if
          end if

        end do

	if( bdebug ) then
	  if( ien .eq. 0 ) then
	    write(156,*) 9,0,0,0,0
	    write(156,*) 'warning: ien not set: ',ien,xn,yn
	  end if
	  write(156,*) 0,0,0,0,0
	  write(156,*) ien,xn,yn
	  write(156,*) '.............'
	end if

        end

c******************************************************************
c******************************************************************
c******************************************************************

	subroutine compute_wave_bottom_stress(h,p,depth,z0,tau)

	implicit none

	real h,p	!wave height and period
	real depth	!depth of water column
	real z0		!bottom roughness
	real tau	!stress at bottom (return)

	include 'pkonst.h'

	real omega,zeta,a,eta,fw,uw
	real, parameter :: pi = 3.14159

	tau = 0.
	if( p == 0. ) return

        omega = 2.*pi/p
        zeta = omega * omega * depth / grav
        if( zeta .lt. 1. ) then
          eta = sqrt(zeta) * ( 1. + 0.2 * zeta )
        else
          eta = zeta * ( 1. + 0.2 * exp(2.-2.*zeta) )
        end if

	if( eta > 80. ) eta = 80.		!GGUZ0
	!write(6,*) eta,p,pi,h,zeta,omega
	!write(6,*) pi * h / ( p * sinh(eta) )

        uw = pi * h / ( p * sinh(eta) )
        a = uw * p / (2.*pi)
        if( a .gt. 0. ) then
          fw = 1.39 * (z0/a)**0.52
        else
          fw = 0.
        end if

        tau = 0.5 * rowass * fw * uw * uw

	end

c******************************************************************

        subroutine make_stress(waeh,waep,z0,tcv,twv,tmv)

c computes stress parameters

	use mod_hydro_baro
	use mod_debug
	use basin, only : nkn,nel,ngr,mbw

        implicit none

        real waeh(nel)	!wave height [m]
        real waep(nel)	!wave period [s]
        real z0
        real tcv(nel)
        real twv(nel)
        real tmv(nel)

        real pi,karm,rho,g
        real depth,ux,uy,uc2
        real h,p
        real aux,cd
        real omega,zeta,eta
        real uw,a,fw
        real tc,tw,tm

        integer ie

        real depele

        pi = 3.14159
        karm = 0.4
        rho = 1025.
        g = 9.81

        do ie = 1,nel

          depth = depele(ie,+1)
          ux = unv(ie)/depth
          uy = vnv(ie)/depth
          uc2 = ux*ux + uy*uy
          h = waeh(ie)
          p = waep(ie)

          aux = (z0 + 0.5 * depth) / z0
          aux = log(aux)
          cd = karm/aux
          cd = cd*cd

          tc = rho * cd * uc2

	  if( p .ne. 0. ) then
            omega = 2.*pi/p
            zeta = omega * omega * depth / g
            if( zeta .lt. 1. ) then
              eta = sqrt(zeta) * ( 1. + 0.2 * zeta )
            else
              eta = zeta * ( 1. + 0.2 * exp(2.-2.*zeta) )
            end if
            !k = eta / depth

            uw = pi * h / ( p * sinh(eta) )
            a = uw * p / (2.*pi)
            if( a .gt. 0. ) then
              fw = 1.39 * (z0/a)**0.52
            else
              fw = 0.
            end if

            tw = 0.5 * rho * fw * uw * uw
            tm = tc * ( 1. + 1.2 * ( tw/(tc+tw) )**3.2 )
	  else
	    tw = 0.
	    tm = tc
	  end if

          if( is_nan(tw) ) then
            write(6,*) "*** nan in stress..."
            write(6,*) ie,tc,tw,tm
            write(6,*) uw,eta,a,fw,depth,h,p
          end if

          tcv(ie) = tc
          twv(ie) = tw
          tmv(ie) = tm
        end do

        end

c******************************************************************

        subroutine get_wave_values(k,wh,wmp,wpp,wd)

c returns significant wave heigh, wave periods (mean and peak) and 
c mean wave direction

	use mod_waves

        implicit none

        integer k
        real wh                 !sign. wave height [m]
        real wmp                !mean wave period [s]
        real wpp                !peak wave period [s]
        real wd                 !mean wave direction [deg]

        wh  = waveh(k)
        wmp = wavep(k)
        wpp = wavepp(k)
        wd  = waved(k)

        end subroutine get_wave_values

!*********************************************************************

	subroutine wave_bottom_stress(tau)

! computes bottom stress from waves (on nodes)

	use basin
	use mod_parwaves
	use mod_waves

	implicit none

	real tau(nkn)

	integer ie
	real h,p,depth
	real tauele(nel)
	real v1v(nkn)

	real depele

	if( iwave == 0 ) then
	  tau = 0.
	  return
	else if( iwave > 1 ) then
	  write(6,*) 'not yet ready for iwave > 1'
	  stop 'error stop wave_bottom_stress: not ready'
	end if

	do ie=1,nel
	  h = waeh(ie)
	  p = waep(ie)
	  depth = depele(ie,1)
	  call compute_wave_bottom_stress(h,p,depth,z0,tauele(ie))
	end do

        call e2n2d(tauele,tau,v1v)

	end

!*********************************************************************

        function has_waves() 

c gives indication if waves are computed

	use mod_waves

        implicit none

        logical has_waves

        if( iwave .le. 0 ) then
          has_waves = .false.
	else if( iwave .gt. 0 .and. iwave .le. 5 ) then
          has_waves = .true.
	else
          has_waves = .false.
	end if

        end function has_waves

!*********************************************************************
