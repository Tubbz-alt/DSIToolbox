function [amp,phas,w,sdamp,sdphas] = funbodeaux(bode,varargin)
%BODEAUX Help function to IDMODEL/BODE and FFPLOT

%   Copyright 1986-2001 The MathWorks, Inc.
%   $Revision: 1.5 $ $Date: 2001/04/06 14:21:57 $
nargin = length(varargin);
if nargout
	err = 0;
	if nargin>2
		err = 1;
	elseif nargin==2&(~isa(varargin{2},'double'))
		err = 1;
	end
	if err
		error(sprintf(['When BODE or FFPLOT is called with output argument the syntax is',...
				'\n [MAG,PHASE] = BODE(Model,W) with W a vector of reals',...
                '\n or [MAG,PHASE,W,SDMAG,SDPHASE] = BODE(Model).']))
	end
    if nargin==2&~bode
        varargin{2}=varargin{2}*2*pi;
    end
	if nargout<4
		[amp,phas,w] = boderesp(varargin{:});
	else
		[amp,phas,w,sdamp,sdphas] = boderesp(varargin{:});
	end
	return
end
newplot
residflag = 0;
if ischar(varargin{end})&strcmp(varargin{end},'resid') % special call from resid
	residflag = 1;
	varargin = varargin(1:end-1);
end
[sys,sysname,PlotStyle,sd,ap,om,mode,fillsd] = sysardec(bode,varargin{:});

if ~bode
   om = om*2*pi;
   if any(om<0)
      disp('Negative frequencies ignored.')
      om = om(find(om>=0));
   end
else
   if any(om<=0)
      disp('Frequencies less or equal to zero ignored')
      om = om(find(om>0));
   end
end
[ynared,unared,yind,uind] = idnamede(sys);
sd1 = sd;
if size(uind,2)==1
	tsu = uind;
elseif isempty(uind)
	tsu = 0;
else
	tsu = sum(uind');
end 
if any(tsu==0) % Then spectra will be plotted
	spplot=1;
else 
	spplot=0;
end
if strcmp(mode,'sep')
	titleadd=[];
else
	titleadd=['Last plotted: '];
end
cols=get(gca,'colororder');
if sum(cols(1,:))>1.5  
	colord=['y','m','c','r','g','w','b']; % Dark background
else
	colord=['b','g','r','c','m','y','k']; % Light background
end

for ks = 1:length(sys)
	sys1 = sys{ks};
	if sd
		if(isa(sys1,'idmodel')&~isa(sys1,'idpoly'))
			[thbbmod,sys1,flag] = idpolget(sys1);
			if flag
				try
					assignin('caller',sysname{ks},sys1)
				catch
				end
			end
			if isempty(thbbmod)
				sys1=pvset(sys1,'CovarianceMatrix','None');
			end
		end
		[mag,phas,w,sdamp,sdphas] = boderesp(sys1,om);
		Mag{ks}=mag;Phas{ks}=phas;W{ks}=w;
		Sdamp{ks}=sdamp;Sdphas{ks}=sdphas;
	else
		[mag,phas,w] = boderesp(sys{ks},om);
		Mag{ks}=mag;Phas{ks}=phas;W{ks}=w;
	end
end 
for yna = 1:length(ynared)
	for una = 1:length(unared)
        MyH=[];
		maxw = -inf; minw = inf;
		maxa = -inf; mina = inf;
		maxp = -inf; minp = inf;
		
		for ks = 1:length(sys)
			if isempty(PlotStyle{ks})
				PStyle=[colord(mod(ks-1,7)+1),'-'];
			else
				PStyle=PlotStyle{ks};
			end
			if uind(ks,una)             
				if yind(ks,yna)&uind(ks,una)
					mag = squeeze(Mag{ks}(yind(ks,yna),uind(ks,una),:));
					phas = squeeze(Phas{ks}(yind(ks,yna),uind(ks,una),:));
					maxw = max(maxw,max(W{ks}));
					minw = min(minw,min(W{ks}));
					maxa = max(maxa,max(mag));
					mina = min(mina,min(mag));
					maxp = max(maxp,max(phas));
					minp = min(minp,min(phas));
					
					if sd
						if isempty(Sdamp{ks})
							sd1 = 0;
						else
							sdamp = Sdamp{ks}(yind(ks,yna),uind(ks,una),:);
							sdphas = Sdphas{ks}(yind(ks,yna),uind(ks,una),:);
							sd1 = sd;
						end
					end
					if ap=='b'
						subplot(211)
					else
						subplot(1,1,1)
					end
					if ap=='b'|ap=='a'
						if bode
							loglog(W{ks},squeeze(mag),PStyle);hold on
						else
							tempH=semilogy(W{ks}/2/pi,squeeze(mag),PStyle);hold on
                            MyH=[MyH; tempH];
                            legend(MyH,'Non-parametric Model','Subspace Model','Non-para Subspace');
						end
						if ap=='a'
                            if bode
                                xlabel('Frequency (rad/s)')
                            else
                                xlabel('Frequency (Hz)')
                            end
                        end
                        
						ylabel('Amplitude')
						if sd1
							%v = axis;
							if fillsd
                                if ks<2
                                    fillcol ='g';
%    								if length(sys) ==1
%				    					fillcol ='y';
%								    else
%    									fillcol = PStyle(1);
%				    				end
    								w = W{ks};
				    				amp2 = squeeze(mag); sdamp2 = squeeze(sdamp);
    								xax=[w;w(end:-1:1)];
                                     if ~bode
                                        xax = xax/2/pi;
                                    end
    								if residflag
				    					bottom = 10^floor(log10(min(amp2)*0.1));
								    	amp2 = zeros(size(amp2));
    								else
				    					bottom = 10^-5;
								    end
    								yax=[amp2+sd*sdamp2;amp2(end:-1:1)-sd*sdamp2(end:-1:1)];
				    				yax=max(yax,bottom);
								    fill(xax,yax,fillcol)
    								if bode
				    					loglog(W{ks},squeeze(mag),PStyle)
    								else
				    					semilogy(W{ks}/2/pi,squeeze(mag),PStyle)
    								end
                                end
							else
                                if ks<2
    								if bode
				    					loglog(W{ks},squeeze(mag)+sd*squeeze(sdamp),[PStyle(1),'-.'])
								    	loglog(W{ks},max(squeeze(mag)-sd*squeeze(sdamp),0),[PStyle(1),'-.'])
    								else
                    					semilogy(W{ks}/2/pi,squeeze(mag)+sd*squeeze(sdamp),[PStyle(1),'-.'])
				    					semilogy(W{ks}/2/pi,max(squeeze(mag)-sd*squeeze(sdamp),0),[PStyle(1),'-.'])
                                    end
								end
								%axis(v)
							end
							if bode
								axis([10^floor(log10(minw)) 10^ceil(log10(maxw)),...
										10^floor(log10(mina)) 10^ceil(log10(maxa))])
							end
						end   
					end
					if ap=='b'
						subplot(212)
					end
					if ap=='b'|ap=='p'
						if bode
							semilogx(W{ks},squeeze(phas),PStyle);hold on
						else
							semilogy(W{ks}/2/pi,squeeze(phas),PStyle);hold on
						end
						ylabel('Phase (degrees)')
                        if bode
                            xlabel('Frequency (rad/s)')
                        else
                            xlabel('Frequency (Hz)')
                        end
						if sd1
							if fillsd
								if length(sys) ==1
									fillcol ='y';
								else
									fillcol = PStyle(1);
								end
								w = W{ks};
								amp2 = squeeze(phas); sdamp2 = squeeze(sdphas);
								xax=[w;w(end:-1:1)];
                                if ~bode
                                    xax = xax/2/pi;
                                end
								yax=[amp2+sd*sdamp2;amp2(end:-1:1)-sd*sdamp2(end:-1:1)];
								%yax=max(yax,10^-5);
								fill(xax,yax,fillcol)
								if bode
									semilogx(W{ks},squeeze(phas),PStyle)
								else
									semilogy(W{ks}/2/pi,squeeze(phas),PStyle)
								end
							else
								%   v = axis;
								if bode
									semilogx(W{ks},squeeze(phas)+sd*squeeze(sdphas),[PStyle(1),'-.'])
									semilogx(W{ks},squeeze(phas)-sd*squeeze(sdphas),[PStyle(1),'-.'])
								else
									semilogy(W{ks}/2/pi,squeeze(phas)+sd*squeeze(sdphas),[PStyle(1),'-.'])
									semilogy(W{ks}/2/pi,squeeze(phas)-sd*squeeze(sdphas),[PStyle(1),'-.'])
								end
							end
							%  axis(v)
						end
						if bode
							try
								axis([10^floor(log10(minw)) 10^ceil(log10(maxw)),...
										100*floor(minp/100) 100*ceil(maxp/100)])
							end
						end
					end
				end
			end
		end
		
		if ap=='b'
			subplot(211)
		end
		title([titleadd,'From ',unared{una},' to ',ynared{yna}])
		if ks<length(sys)|yna~=length(ynared) |una~=length(unared) | spplot
			try
                legend(MyH,'Non-parametric Model','Subspace Model','Non-para Subspace');
				pause
			catch
				hold off
				set(gcf,'NextPlot','replace');
				return
			end  
			if strcmp(mode,'sep')
				if ap=='b'
					subplot(211),cla,hold off
					subplot(212),cla,hold off
				else
					subplot(1,1,1),cla,hold off
				end
			end
		end
		
		if strcmp(mode,'sep')
			if ap=='b'
				subplot(211),hold off
				subplot(212),hold off
			else
				subplot(1,1,1),hold off
			end
		end 
	end
end
if strcmp(mode,'same')
	if ap=='b'
		subplot(211),hold off
		subplot(212),hold off
	else
		subplot(1,1,1),cla,hold off
	end
end 

%% Now for possible spectra
if spplot
	for yna = 1:length(ynared)
        MyH=[];
		maxw = -inf; minw = inf;
		maxa = -inf; mina = inf;       
		for ks = 1:length(sys)
			if isempty(PlotStyle{ks})
				PStyle=[colord(mod(ks-1,7)+1),'-'];
			else
				PStyle=PlotStyle{ks};
         end
         tsfl = tsflag(sys{ks});
			if ~sum(uind(ks,:))           
				if yind(ks,yna) 
					mag = squeeze(Mag{ks}(yind(ks,yna),yind(ks,yna),:));
					maxw = max(maxw,max(W{ks}));
					minw = min(minw,min(W{ks}));
					maxa = max(maxa,max(mag));
					mina = min(mina,min(mag));
					if sd
						if isempty(Sdamp{ks})
							sd1=0;
						else
							sdamp = Sdamp{ks}(yind(ks,yna),yind(ks,yna),:);
							sd1 = sd;
						end
					end
					subplot(1,1,1), 
					if bode
						loglog(W{ks},squeeze(mag),PStyle);hold on
					else
						tempH=semilogy(W{ks}/2/pi,squeeze(mag),PStyle);hold on
                        MyH=[MyH;tempH];
                        legend(MyH,'Non-parametric Model','Subspace Model','Non-para Subspace');
					end
                    if bode
                            xlabel('Frequency (rad/s)')
                        else
                            xlabel('Frequency (Hz)')
                        end
                        ylabel('Power')
					if sd1
						if fillsd
							if length(sys) ==1
								fillcol ='y';
							else
								fillcol = PStyle(1);
							end
							w = W{ks};
							amp2 = squeeze(mag); sdamp2 = squeeze(sdamp);
							xax=[w;w(end:-1:1)];
                            if ~bode
                                    xax = xax/2/pi;
                                end
							yax=[amp2+sd*sdamp2;amp2(end:-1:1)-sd*sdamp2(end:-1:1)];
							yax=max(yax,10^-5);
                            
                            if ks < 2
                                fillcol='y';
    							fill(xax,yax,fillcol)
                            end
                            
							if bode
								loglog(W{ks},squeeze(mag),PStyle)
							else
								semilogy(W{ks}/2/pi,squeeze(mag),PStyle)
							end
						else
							if bode
								loglog(W{ks},squeeze(mag)+sd*squeeze(sdamp),[PStyle(1),'-.'])
								loglog(W{ks},max(squeeze(mag)-sd*squeeze(sdamp),0),[PStyle(1),'-.'])
							else
								semilogy(W{ks}/2/pi,squeeze(mag)+sd*squeeze(sdamp),[PStyle(1),'-.'])
								semilogy(W{ks}/2/pi,max(squeeze(mag)-sd*squeeze(sdamp),0),[PStyle(1),'-.'])
							end
						end
						if bode
							axis([10^floor(log10(minw)) 10^ceil(log10(maxw)),...
									10^floor(log10(mina)) 10^ceil(log10(maxa))])
						end
					end          
				end
			end
		end 
      if strcmp(tsfl,'NoiseModel')
         texsp = 'Spectrum for disturbance at output ';
      else
         texsp = 'Power spectrum for signal ';
      end
      
		title([titleadd,texsp,ynared{yna}]),
		if ks<length(sys)|yna~=length(ynared) 
			try
                legend(MyH,'Non-parametric Model','Subspace Model','Non-para Subspace');
				pause
			catch
				hold off
				set(gcf,'NextPlot','replace');
				return
			end 
		end
		if strcmp(mode,'sep')
			hold off
		end
	end
end
hold off
set(gcf,'NextPlot','replace');
