c
c $Id: newtvd.f,v 1.5 2009-04-07 10:43:57 georg Exp $
c
c tvd routines
c
c contents :
c
c subroutine tvd_init(itvd)				initializes tvd scheme
c subroutine tvd_grad_3d(cc,gx,gy,aux,nlvdi,nlv)	computes gradients 3D
c subroutine tvd_grad_2d(cc,gx,gy,aux)			computes gradients 2D
c subroutine tvd_get_upwind_c(ie,l,ic,id,cu,cv)		c of upwind node
c subroutine tvd_upwind_init				init x,y of upwind node
c subroutine tvd_fluxes(ie,l,itot,isum,dt,cl,cv,gxv,gyv,f,fl) tvd fluxes
c
c revision log :
c
c 02.02.2009	ggu&aac	all tvd routines into seperate file
c 24.03.2009	ggu	bug fix: isum -> 6; declaration of cl() was missing 0
c 30.03.2009	ggu	bug fix: ilhv was real in tvd_get_upwind()
c 31.03.2009	ggu	bug fix: do not use internal gradient (undershoot)
c 06.04.2009	ggu&ccf	bug fix: in tvd_fluxes() do not test for conc==cond
c 15.12.2010	ggu	new routines for vertical tvd: vertical_flux_*()
c 28.01.2011	ggu	bug fix for distance with lat/lon (tvd_fluxes)
c 29.01.2011	ccf	insert ISPHE for lat-long coordinates
c
c*****************************************************************
c
c notes :
c
c itvd = 0	no tvd
c itvd = 1	run tvd with gradient information using average
c itvd = 2	run tvd with gradient computed from up/down wind nodes
c
c itvd == 2 is the better scheme
c
c*****************************************************************

        subroutine tvd_init(itvd)

c initializes tvd scheme

        implicit none

	integer itvd

	include 'param.h'
	include 'tvd.h'

	integer icall
	save icall
	data icall /0/

	if( icall .ne. 0 ) return

	icall = 1

	itvd_type = itvd

	if( itvd_type .eq. 2 ) call tvd_upwind_init

	write(6,*) 'TVD scheme: ',itvd

	end

c*****************************************************************

        subroutine tvd_grad_3d(cc,gx,gy,aux,nlvdi,nlv)

c computes gradients for scalar cc (average gradient information)

        implicit none

	integer nlvdi,nlv
	real cc(nlvdi,1)
	real gx(nlvdi,1)
	real gy(nlvdi,1)
	real aux(nlvdi,1)

        integer nkn,nel,nrz,nrq,nrb,nbc,ngr,mbw
        common /nkonst/nkn,nel,nrz,nrq,nrb,nbc,ngr,mbw
        
        integer nen3v(3,1)
        common /nen3v/nen3v        
	integer ilhv(1), ilhkv(1)
	common /ilhv/ilhv, /ilhkv/ilhkv
	include 'ev.h'
        
        integer k,l,ie,ii,lmax
	real b,c,area
	real ggx,ggy

	do k=1,nkn
	  lmax = ilhkv(k)
	  do l=1,lmax
	    gx(l,k) = 0.
	    gy(l,k) = 0.
	    aux(l,k) = 0.
	  end do
	end do

        do ie=1,nel
          area=ev(10,ie) 
	  lmax = ilhv(ie)
	  do l=1,lmax
            ggx=0
            ggy=0
            do ii=1,3
              k=nen3v(ii,ie)
              b=ev(ii+3,ie)
              c=ev(ii+6,ie)
              ggx=ggx+cc(l,k)*b
              ggy=ggy+cc(l,k)*c
              aux(l,k)=aux(l,k)+area
	    end do
            do ii=1,3
             k=nen3v(ii,ie)
             gx(l,k)=gx(l,k)+ggx*area
             gy(l,k)=gy(l,k)+ggy*area
            end do 
          end do
        end do

        do k=1,nkn
	  lmax = ilhkv(k)
	  do l=1,lmax
	    area = aux(l,k)
	    if( area .gt. 0. ) then
	      gx(l,k) = gx(l,k) / area
	      gy(l,k) = gy(l,k) / area
	    end if
	  end do
        end do

        end
        
c*****************************************************************

        subroutine tvd_grad_2d(cc,gx,gy,aux)

c computes gradients for scalar cc (only 2D - used in sedi3d)

        implicit none

	real cc(1)
	real gx(1)
	real gy(1)
	real aux(1)

        integer nkn,nel,nrz,nrq,nrb,nbc,ngr,mbw
        common /nkonst/nkn,nel,nrz,nrq,nrb,nbc,ngr,mbw
        
        integer nen3v(3,1)
        common /nen3v/nen3v        
	include 'ev.h'
        
        integer k,ie,ii
	real b,c,area
	real ggx,ggy

	do k=1,nkn
	  gx(k) = 0.
	  gy(k) = 0.
	  aux(k) = 0.
	end do

        do ie=1,nel
          area=ev(10,ie) 
          ggx=0
          ggy=0
          do ii=1,3
              k=nen3v(ii,ie)
              b=ev(ii+3,ie)
              c=ev(ii+6,ie)
              ggx=ggx+cc(k)*b
              ggy=ggy+cc(k)*c
              aux(k)=aux(k)+area
	  end do
          do ii=1,3
             k=nen3v(ii,ie)
             gx(k)=gx(k)+ggx*area
             gy(k)=gy(k)+ggy*area
          end do 
        end do

        do k=1,nkn
	    area = aux(k)
	    if( area .gt. 0. ) then
	      gx(k) = gx(k) / area
	      gy(k) = gy(k) / area
	    end if
        end do

        end
        
c*****************************************************************

        subroutine tvd_get_upwind_c(ie,l,ic,id,cu,cv)

c computes concentration of upwind node (using info on upwind node)

        implicit none

        include 'param.h'
        include 'tvd.h'

        integer ie,l
	integer ic,id
        real cu
        real cv(nlvdim,1)

        integer nen3v(3,1)
        common /nen3v/nen3v        
	integer ilhv(1)			!BUG fix
	common /ilhv/ilhv

        integer ienew
        integer ii,k
        real xu,yu
        real c(3)

        xu = tvdupx(id,ic,ie)
        yu = tvdupy(id,ic,ie)
        ienew = ietvdup(id,ic,ie)

        if( ienew .le. 0 ) return
	if( ilhv(ienew) .lt. l ) return		!TVD for 3D

        do ii=1,3
          k = nen3v(ii,ienew)
          c(ii) = cv(l,k)
        end do

        call femintp(ienew,c,xu,yu,cu)

        end

c*****************************************************************

        subroutine tvd_upwind_init

c initializes position of upwind node
c
c sets position and element of upwind node

        implicit none

        include 'param.h'
        include 'tvd.h'

        integer ie,ii,j,k
        integer ienew
        real xc,yc,xd,yd,xu,yu

        integer nkn,nel,nrz,nrq,nrb,nbc,ngr,mbw
        common /nkonst/nkn,nel,nrz,nrq,nrb,nbc,ngr,mbw
        integer nen3v(3,1)
        common /nen3v/nen3v
        real xgv(1)
        common /xgv/xgv
        real ygv(1)
        common /ygv/ygv
        double precision xlon1,ylat1,xlon2,ylat2,xlon3,ylat3    !lat/long [rad]
        double precision dlat0,dlon0                    !center of projection
        double precision xx,yy
        double precision one,four,rad,pi
        integer isphe_ev,init_ev
        common /evcommon/ isphe_ev,init_ev
        integer kn1,kn2,kn3
        integer isphe

        write(6,*) 'setting up tvd upwind information...'

        one = 1.
        four = 4.

        pi=four*atan(one)
        rad = 180./pi

        call check_spheric_ev   !checks and sets isphe_ev

        isphe = isphe_ev

        do ie=1,nel

          if ( isphe .eq. 1 ) then
            kn1=nen3v(1,ie)
            kn2=nen3v(2,ie)
            kn3=nen3v(3,ie)
            xlon1=xgv(kn1)/rad
            ylat1=ygv(kn1)/rad
            xlon2=xgv(kn2)/rad
            ylat2=ygv(kn2)/rad
            xlon3=xgv(kn3)/rad
            ylat3=ygv(kn3)/rad
            dlon0 = (xlon1+xlon2+xlon3) / 3.
            dlat0 = (ylat1+ylat2+ylat3) / 3.
          end if

          do ii=1,3

            k = nen3v(ii,ie)
            xc = xgv(k)
            yc = ygv(k)

            j = mod(ii,3) + 1
            k = nen3v(j,ie)
            xd = xgv(k)
            yd = ygv(k)

	    if ( isphe .eq. 1 ) then
              xc = xc/rad
              yc = yc/rad
              call cpp(xx,yy,xc,yc,dlon0,dlat0)
              xc = xx
              yc = yy
              xd = xd/rad
              yd = yd/rad
              call cpp(xx,yy,xd,yd,dlon0,dlat0)
              xd = xx
              yd = yy
	    end if

            xu = 2*xc - xd
            yu = 2*yc - yd
            call find_elem_from_old(ie,xu,yu,ienew)
            tvdupx(j,ii,ie) = xu
            tvdupy(j,ii,ie) = yu
            ietvdup(j,ii,ie) = ienew

            j = mod(ii+1,3) + 1
            k = nen3v(j,ie)
            xd = xgv(k)
            yd = ygv(k)

	    if ( isphe .eq. 1 ) then
              xd = xd/rad
              yd = yd/rad
              call cpp(xx,yy,xd,yd,dlon0,dlat0)
              xd = xx
              yd = yy
	    end if

            xu = 2*xc - xd
	    yu = 2*yc - yd

	    call find_elem_from_old(ie,xu,yu,ienew)
            tvdupx(j,ii,ie) = xu
            tvdupy(j,ii,ie) = yu
            ietvdup(j,ii,ie) = ienew

            tvdupx(ii,ii,ie) = 0.
            tvdupy(ii,ii,ie) = 0.
            ietvdup(ii,ii,ie) = 0

          end do
        end do

        write(6,*) '...tvd upwind setup done (itvd=2)'

        end

c*****************************************************************

	subroutine tvd_fluxes(ie,l,itot,isum,dt,cl,cv,gxv,gyv,f,fl)

c computes tvd fluxes for one element

	implicit none

	include 'param.h'
        include 'tvd.h'
        include 'ev.h'

	integer ie,l
	integer itot,isum
	double precision dt
	double precision cl(0:nlvdim+1,3)		!bug fix
	real cv(nlvdim,nkndim)
        real gxv(nlvdim,nkndim)
        real gyv(nlvdim,nkndim)
	double precision f(3)
	double precision fl(3)

	real eps
	parameter (eps=1.e-8)

        integer nen3v(3,1)
        common /nen3v/nen3v
        real xgv(1)
        common /xgv/xgv
        real ygv(1)
        common /ygv/ygv
        real ulnv(nlvdim,1), vlnv(nlvdim,1)
        common /ulnv/ulnv, /vlnv/vlnv

        logical bgradup
        logical bdebug
	integer ii,k
        integer ic,kc,id,kd,ip,iop
        real term,fact,grad
        real conc,cond,conf,conu
        real gcx,gcy,dx,dy
        real u,v
        real rf,psi
        real alfa,dis,aj
        real vel
        real gdx,gdy

	bgradup = .true.
	bgradup = itvd_type .eq. 2
	bdebug = .true.
	bdebug = .false.

	if( bdebug ) then
	  write(6,*) 'tvd: ',ie,l,itot,isum,dt
	  write(6,*) 'tvd: ',bgradup,itvd_type
	end if

	  do ii=1,3
	    fl(ii) = 0.
	  end do

	  if( itot .lt. 1 .or. itot .gt. 2 ) return

	  u = ulnv(l,ie)
          v = vlnv(l,ie)
	  aj = 24 * ev(10,ie)

            ip = isum
            if( itot .eq. 2 ) ip = 6 - ip		!bug fix

            do ii=1,3
              if( ii .ne. ip ) then
                if( itot .eq. 1 ) then			!flux out of one node
                  ic = ip
                  id = ii
                  fact = 1.
                else					!flux into one node
                  id = ip
                  ic = ii
                  fact = -1.
                end if
                kc = nen3v(ic,ie)
                conc = cl(l,ic)
                kd = nen3v(id,ie)
                cond = cl(l,id)

                !dx = xgv(kd) - xgv(kc)
                !dy = ygv(kd) - ygv(kc)
                !dis = sqrt(dx**2 +dy**2)
		! next is bug fix for lat/lon
		iop = 6 - (id+ic)			!opposite node of id,ic
		dx = aj * ev(6+iop,ie)
		if( 1+mod(iop,3) .eq. id ) dx = -dx
		dy = aj * ev(3+iop,ie)
		if( 1+mod(iop,3) .eq. ic ) dy = -dy
		dis = ev(16+iop,ie)

                !vel = sqrt(u**2 + v**2)                !total velocity
                vel = abs( u*dx + v*dy ) / dis          !projected velocity
                alfa = ( dt * vel  ) / dis

                if( bgradup ) then
                  conu = cond
                  !conu = 2.*conc - cond		!use internal gradient
                  call tvd_get_upwind_c(ie,l,ic,id,conu,cv)
                  grad = cond - conu
                else
                  gcx = gxv(l,kc)
                  gcy = gyv(l,kc)
                  grad = 2. * (gcx*dx + gcy*dy)
                end if

                if( abs(conc-cond) .lt. eps ) then	!BUG -> eps
                  rf = -1.
                else
                  rf = grad / (cond-conc) - 1.
                end if

                psi = max(0.,min(1.,2.*rf),min(2.,rf))  ! superbee
c               psi = ( rf + abs(rf)) / ( 1 + abs(rf))  ! muscl
c               psi = max(0.,min(2.,rf))                ! osher
c               psi = max(0.,min(1.,rf))                ! minmod

                conf = conc + 0.5*psi*(cond-conc)*(1.-alfa)
                term = fact * conf * f(ii)
                fl(ic) = fl(ic) - term
                fl(id) = fl(id) + term
              end if
            end do

	if( bdebug ) then
	  write(6,*) 'tvd: --------------'
	  write(6,*) 'tvd: ',vel,gcx,gcy,grad
	  write(6,*) 'tvd: ',rf,psi,alfa
	  write(6,*) 'tvd: ',conc,cond,conf
	  write(6,*) 'tvd: ',term,fact
	  write(6,*) 'tvd: ',f
	  write(6,*) 'tvd: ',fl
	  write(6,*) 'tvd: ',(cl(l,ii),ii=1,3)
	  write(6,*) 'tvd: ',ic,id,kc,kd
	  write(6,*) 'tvd: --------------'
	end if

	end

c*****************************************************************

	subroutine vertical_flux_k(k,dt,wsink,cv,vvel,vflux)

c computes vertical fluxes of concentration - nodal version

c do not use this version !!!!!!!!!!!!

c ------------------- l-2 -----------------------
c      u              l-1
c ------------------- l-1 -----------------------
c      c               l     ^        d
c ---------------+---  l  ---+-------------------
c      d         v    l+1             c
c ------------------- l+1 -----------------------
c                     l+2             u
c ------------------- l+2 -----------------------

	implicit none

	include 'param.h'

	integer k			!node of vertical
	real dt				!time step
	real wsink			!sinking velocity (positive downwards)
	real cv(nlvdim,nkndim)		!scalar to be advected
	real vvel(0:nlvdim)		!velocities at interface (return)
	real vflux(0:nlvdim)		!fluxes at interface (return)

	integer ilhkv(1)
	common /ilhkv/ilhkv
	real wprv(0:nlvdim,1)
	common /wprv/wprv
        real hdknv(nlvdim,1)
        common /hdknv/hdknv

        real eps
        parameter (eps=1.e-8)

	logical btvdv
	integer l,lmax,lu
	real w,fl
	real conc,cond,conu,conf
	real hdis,alfa,rf,psi

	btvdv = .false.			!use tvd ?

	lmax = ilhkv(k)

	do l=1,lmax-1
	  w = wprv(l,k) - wsink

	  if( w .gt. 0. ) then
	    conc = cv(l+1,k)
	  else
	    conc = cv(l,k)
	  end if

	  conf = conc

	  if( btvdv ) then
	    if( w .gt. 0. ) then
	      !conc = cv(l+1,k)
	      cond = cv(l,k)
	      conu = cond
	      lu = l + 2
	      if( lu .le. lmax ) conu = cv(lu,k)
	    else
	      !conc = cv(l,k)
	      cond = cv(l+1,k)
	      conu = cond
	      lu = l - 1
	      if( lu .ge. 1 ) conu = cv(lu,k)
	    end if

	    hdis = 0.5*(hdknv(l,k)+hdknv(l+1,k))
	    alfa = dt * abs(w) / hdis
            if( abs(conc-cond) .lt. eps ) then
              rf = -1.
            else
              rf = (cond-conu) / (cond-conc) - 1.
            end if
            psi = max(0.,min(1.,2.*rf),min(2.,rf))  ! superbee
            conf = conc + 0.5*psi*(cond-conc)*(1.-alfa)
	  end if

	  vvel(l) = w
	  vflux(l) = w * conf
	end do

	vvel(0) = 0.			!surface
	vflux(0) = 0.
	vvel(lmax) = 0.			!bottom
	vflux(lmax) = 0.

	end

c*****************************************************************

	subroutine vertical_flux_ie(btvdv,ie,lmax,dt,wsink
     +					,cl,wvel,hold,vflux)

c computes vertical fluxes of concentration - element version

c ------------------- l-2 -----------------------
c      u              l-1
c ------------------- l-1 -----------------------
c      c               l     ^        d
c ---------------+---  l  ---+-------------------
c      d         v    l+1             c
c ------------------- l+1 -----------------------
c                     l+2             u
c ------------------- l+2 -----------------------

	implicit none

	include 'param.h'

	logical btvdv				!use tvd?
	integer ie				!element
	integer lmax				!total number of layers
	double precision dt			!time step
	double precision wsink			!sinking velocity (+ downwards)
	double precision cl(0:nlvdim+1,3)	!scalar to be advected
	double precision hold(0:nlvdim+1,3)	!depth of layers
	double precision wvel(0:nlvdim+1,3)	!velocities at interface
	double precision vflux(0:nlvdim+1,3)	!fluxes at interface (return)

        double precision eps
        parameter (eps=1.e-8)

	integer ii,l,lu
	double precision w,fl
	double precision conc,cond,conu,conf
	double precision hdis,alfa,rf,psi

	do ii=1,3
	 do l=1,lmax-1
	  w = wvel(l,ii) - wsink

	  if( w .gt. 0. ) then
	    conc = cl(l+1,ii)
	  else
	    conc = cl(l,ii)
	  end if

	  conf = conc

	  if( btvdv ) then
	    if( w .gt. 0. ) then
	      !conc = cl(l+1,ii)
	      cond = cl(l,ii)
	      conu = cond
	      lu = l + 2
	      if( lu .le. lmax ) conu = cl(lu,ii)
	    else
	      !conc = cl(l,ii)
	      cond = cl(l+1,ii)
	      conu = cond
	      lu = l - 1
	      if( lu .ge. 1 ) conu = cl(lu,ii)
	    end if

	    hdis = 0.5*(hold(l,ii)+hold(l+1,ii))
	    alfa = dt * abs(w) / hdis
            if( abs(conc-cond) .lt. eps ) then
              rf = -1.
            else
              rf = (cond-conu) / (cond-conc) - 1.
            end if
            psi = max(0.,min(1.,2.*rf),min(2.,rf))  ! superbee
            conf = conc + 0.5*psi*(cond-conc)*(1.-alfa)
	  end if

	  vflux(l,ii) = w * conf
	 end do
	 vflux(0,ii) = 0.
	 vflux(lmax,ii) = 0.
	end do

	end

c*****************************************************************

