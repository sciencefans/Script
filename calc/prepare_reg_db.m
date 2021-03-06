function reg_db = prepare_reg_db( bodydb, facerect )
%bodydb.bbox:   [l u r b];
%facerect:      [l u w h];
    errorid = zeros(numel(bodydb),1);
    label = zeros(numel(bodydb),4);
    largebox = zeros(numel(bodydb),4);
    if ~isempty(bodydb)
%         reg_db.bodyloc = bodydb.bbox;
        reg_db.dir = cellfun(@(x)x.dir, bodydb, 'UniformOutput', false);
        parfor i = 1 : size(facerect, 1)
            fullp = bodydb{i}.dir;
            try
                img = imread(fullp);
            catch
                errorid(i) = 1;
            end
            predicted = bodydb{i}.bbox;
            headbbox = [facerect(i, 1) facerect(i, 2)...
                facerect(i, 1)+facerect(i, 3) facerect(i, 2)+facerect(i, 4)];
            overlap = arrayfun(@(x) calcOverlap(predicted(x,1:4), headbbox, 3)*100+predicted(x,5), 1:size(predicted,1));
            [~, maxid] = max(overlap);
            if overlap(maxid) >= 50
                lurd = predicted(maxid,1:4);
                predicted = predicted(maxid,:);
    %             roi = imresize(img(floor(lurd(2)+0.5):floor(0.5+lurd(4)),floor(lurd(1)+0.5):floor(lurd(3)+0.5),:), [224, 224]);
                re_ratio = [224 224]./[lurd(3)-lurd(1) lurd(4)-lurd(2)];
                label(i,:) = [headbbox(1)-predicted(1),headbbox(2)-predicted(2),...
                    headbbox(3)-predicted(1),headbbox(4)-predicted(2)].*[re_ratio re_ratio];
            else
                u = floor(max(facerect(i, 2)-facerect(i, 4), 1)+0.5);
                l = floor(max(facerect(i, 1)-1.5*facerect(i, 3), 1)+0.5);
                d = floor(min(u+6*facerect(i, 4), size(img, 1))+0.5);
                r = floor(min(facerect(i, 1)+2.5*facerect(i, 3), size(img, 2))+0.5);
    %             roi = imresize(img(u:d,l:r,:), [224, 224]);
                re_ratio = [224 224]./[r-l d-u];
                label(i,:) = [headbbox(1)-l,headbbox(2)-u,...
                    headbbox(3)-l,headbbox(4)-u].*[re_ratio re_ratio];
                lurd = [l u r d];
            end
            largebox(i,:) = lurd;
        end
        errorid = find(errorid==1);
        if numel(errorid) > 0
            fprintf('Reading %d images error\n', numel(errorid));
            label(errorid,:)=[];
            largebox(errorid,:) = [];
        end
        reg_db.largebox = largebox;
        reg_db.targetbox = label;
        reg_db.order_bbox = 'lurd';
    end
end

