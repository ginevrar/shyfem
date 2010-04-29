c
c utility routines
c
c 29.04.2010    ggu     new file from nosaver
c
c***************************************************************

	subroutine make_vert_aver(nlvdim,nkn,ilhkv,cv3,vol3,cv2)

	implicit none

	integer nlvdim
	integer nkn
	integer ilhkv(1)
	real cv3(nlvdim,1)
	real vol3(nlvdim,1)
	real cv2(1)

	integer k,l,lmax
	double precision c,v
	double precision cctot,vvtot

	do k=1,nkn
	  cctot = 0.
	  vvtot = 0.
	  lmax = ilhkv(k)
	  do l=1,lmax
	    c = cv3(l,k)
	    v = vol3(l,k)
	    cctot = cctot + c*v
	    vvtot = vvtot + v
	  end do
	  cctot = cctot / vvtot
	  cv2(k) = cctot
	end do

	end

c***************************************************************

	subroutine make_aver(nlvdim,nkn,ilhkv,cv3,vol3,cmin,cmax,cmed,vtot)

	implicit none

	integer nlvdim
	integer nkn
	integer ilhkv(1)
	real cv3(nlvdim,1)
	real vol3(nlvdim,1)
	real cmin,cmax,cmed,vtot

	integer k,l,lmax
	real c,v
	double precision cctot,vvtot

	cmin = cv3(1,1)
	cmax = cv3(1,1)
	cctot = 0.
	vvtot = 0.

	do k=1,nkn
	  lmax = ilhkv(k)
	  do l=1,lmax
	    c = cv3(l,k)
	    v = vol3(l,k)
	    cmin = min(cmin,c)
	    cmax = max(cmax,c)
	    cctot = cctot + c*v
	    vvtot = vvtot + v
	  end do
	end do

	cmed = cctot / vvtot
	vtot = vvtot

	end

c***************************************************************

	subroutine make_acumulate(nlvdim,nkn,ilhkv,cv3,cvacu)

	implicit none

	integer nlvdim
	integer nkn
	integer ilhkv(1)
	real cv3(nlvdim,1)
	real cvacu(nlvdim,1)

	integer k,l,lmax

        do k=1,nkn
          lmax = ilhkv(k)
          do l=1,lmax
            cvacu(l,k) = cvacu(l,k) + cv3(l,k)
          end do
        end do

	end

c***************************************************************
c***************************************************************
c***************************************************************

	subroutine open_nos_file(name,status,nunit)

	implicit none

	character*(*) name,status
	integer nunit

	integer nb
	character*80 file

        integer ifileo

	call mkname(' ',name,'.nos',file)
	nb = ifileo(0,file,'unform',status)
	if( nb .le. 0 ) stop 'error stop open_nos_file: opening file'

	nunit = nb

	end

c***************************************************************
c***************************************************************
c***************************************************************

	subroutine init_volume(nlvdim,nkn,nel,nlv,ilhkv,hlv,hev,vol3)

c initializes volumes just in case no volume file is found
c
c we just set everything to 1.
c we could do better using information on node area and depth structure

	implicit none

	integer nlvdim
	integer nkn,nel,nlv
	integer ilhkv(1)
	real hlv(1)
	real hev(1)
	real vol3(nlvdim,1)

	integer k,l,lmax

	do k=1,nkn
	  lmax = ilhkv(k)
	  do l=1,nlv
	    vol3(l,k) = 1.
	  end do
	end do

	end

c***************************************************************

	subroutine get_volume(nvol,it,nlvdim,ilhkv,vol3)

c reads volumes

	implicit none

	integer nvol
	integer it
	integer nlvdim
	integer ilhkv(1)
	real vol3(nlvdim,1)

	integer ivar,ierr

	integer icall,itold
	save icall,itold
	data icall,itold /0,0/

	if( icall .gt. 0 .and. it .eq. itold ) return	!already read
	if( icall .le. 0 ) itold = it - 1		!force read
	if( it .lt. itold ) goto 95			!error - it too small

	do while( itold .lt. it )
	  call rdnos(nvol,itold,ivar,nlvdim,ilhkv,vol3,ierr)
          if(ierr.gt.0) goto 94			!read error
          if(ierr.ne.0) goto 93			!EOF
          if(ivar.ne.66) goto 92		!ivar should be 66
	end do

	icall = 1
	if( it .lt. itold ) goto 95		!HACK - just temporary
	if( itold .ne. it ) goto 96

	return
   92	continue
	write(6,*) ivar,66
	stop 'error stop nosaver: wrong variable'
   93	continue
	stop 'error stop nosaver: EOF found reading nos file'
   94	continue
	stop 'error stop nosaver: error reading nos file'
   95	continue
	write(6,*) 'it in vol file is higher than requested: ',itold,it
	return		!FIXME -> should signal error
	stop 'error stop nosaver: it too small'
   96	continue
	write(6,*) it,itold
	stop 'error stop nosaver: no vol record for it'
	end

c***************************************************************
c***************************************************************
c***************************************************************

	subroutine check_equal_i(text,n,ia1,ia2)

c tests array to be equal

	implicit none

	character*(*) text
	integer n
	integer ia1(1)
	integer ia2(1)

	integer i

	do i=1,n
	  if( ia1(i) .ne. ia2(i) ) goto 99
	end do

	return
   99	continue
	write(6,*) 'arrays are not equal: ',text
	stop 'error stop check_iqual: arrays differ'
	end

c***************************************************************

	subroutine check_equal_r(text,n,ra1,ra2)

c tests array to be equal

	implicit none

	character*(*) text
	integer n
	real ra1(1)
	real ra2(1)

	integer i

	do i=1,n
	  if( ra1(i) .ne. ra2(i) ) goto 99
	end do

	return
   99	continue
	write(6,*) 'arrays are not equal: ',text
	stop 'error stop check_iqual: arrays differ'
	end

c***************************************************************

