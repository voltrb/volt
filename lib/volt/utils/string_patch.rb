if RUBY_PLATFORM == 'opal'
  class String
    def split(pattern = undefined, limit = undefined)
      %x{
        console.log('split: ', pattern, limit)
        if (self.length === 0) {
          return [];
        }
        if (limit === undefined) {
          limit = 0;
        } else {
          limit = #{Opal.coerce_to!(limit, Integer, :to_int)};
          if (limit === 1) {
            return [self];
          }
        }
        if (pattern === undefined || pattern === nil) {
          pattern = #{$; || ' '};
        }
        var result = [],
            string = self.toString(),
            index = 0,
            match,
            i;
        if (pattern.$$is_regexp) {
          pattern = new RegExp(pattern.source, 'gm' + (pattern.ignoreCase ? 'i' : ''));
        } else {
          pattern = #{Opal.coerce_to(pattern, String, :to_str).to_s};
          if (pattern === ' ') {
            pattern = /\s+/gm;
            string = string.replace(/^\s+/, '');
          } else {
            pattern = new RegExp(pattern.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'gm');
          }
        }
        console.log('pattern: ', pattern, string, result);
        result = string.split(pattern);

        while ((i = result.indexOf(undefined)) !== -1) {
          result.splice(i, 1);
        }
        if (limit === 0) {
          while (result[result.length - 1] === '') {
            result.length -= 1;
          }
          return result;
        }
        match = pattern.exec(string);
        if (match === null && limit > 0) {
          // result length should be 1, push nil until limit
          return result;
        }

        if (limit < 0) {
          if (match !== null && match[0] === '' && pattern.source.indexOf('(?=') === -1) {
            for (i = 0; i < match.length; i++) {
              result.push('');
            }
          }
          return result;
        }
        console.log('match: ', match);
        if (match !== null && match[0] === '') {
          result.splice(limit - 1, result.length - 1, result.slice(limit - 1).join(''));
          return result;
        }
        i = 0;
        while (match !== null) {
          i++;
          index = pattern.lastIndex;
          if (i + 1 === limit) {
            break;
          }
          match = pattern.exec(string);
        }
        console.log('result11: ', result);
        result.splice(limit - 1, result.length - 1, string.slice(index));
        return result;
      }
    end
  end
end