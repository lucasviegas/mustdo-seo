package MUSTdoSEO::DB::ParserTools;


use strict;
use lib '../../';
use MUSTdoSEO::DB;
use MUSTdoSEO::Functions qw(set_error);
use Data::Dumper;
use vars qw(@ISA);
@ISA = qw(MUSTdoSEO::DB);

our $VERSION = sprintf "%d.%d", q$Revision: 1.1 $ =~ /(\d+)/g;



sub load_urls_to_parse
{
   my($self, $arg) = @_;
   
   $arg->{'to_parse'}     = 1;
   $arg->{'url_url_text'} = $arg->{'root_url'};

   $self->load_urls($arg)
   or do
   {
      $arg->{'ERROR'} = &set_erro(__PACKAGE__, __LINE__, 'erro na execucao da query|'.$self->{'dbh'}->errstr);
      return 0; 
   };
   
   return 1;
}


sub load_urls
{
   my($self, $arg) = @_;
   my($sql, $sth, @param);
   
   ## Building query
   $sql  =   'SELECT url_id, ';
   $sql .=          'url_processed, ';
   $sql .=          'url_url_text, ';
   $sql .=          'url_title_list, ';
   $sql .=          'url_description_list, ';
   $sql .=          'url_script_src_list, ';
   $sql .=          'url_url_text_md5_hex ';
   $sql .=     'FROM urls ';
   $sql .=    'WHERE url_processed is null or url_processed = 0 AND url_url_text like \''.$arg->{'url_url_text'}.'%\''      if ($arg->{'to_parse'});
   $sql .=    'WHERE url_processed is not null or url_processed <> 0' if ($arg->{'analyzed'});
   $sth  = $self->{'dbh'}->prepare($sql);
   
   ## Running query
   unless($sth->execute(@param))
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;       
   }
   
   delete($arg->{'data'});
   $arg->{'rows'} = $sth->rows;
   
   ## Recovering urls
   foreach my $i (0..($sth->rows)-1)
   {
      my $r = $sth->fetchrow_hashref;
      map {utf8::encode($r->{$_})} keys %{$r};
      
      push @{$arg->{'data'}}, $r;
   }

   $sth->finish;

   return 1;
}


sub load_url
{
   my($self, $arg) = @_;
   my($sql, $sth, %fields_db, @param);
   
   %fields_db = (
      url_id                    => 1, 
      url_processed             => 1, 
      url_url_text_md5_hex      => 1, 
      url_url_text              => 1, 
      url_inlink_canonical_list => 1, 
      url_canonical_list        => 1, 
      url_inlink_list           => 1, 
      url_inlink_anchor_text    => 1, 
      url_title_list            => 1, 
      url_description_list      => 1, 
      url_internal_link_list    => 1, 
      url_external_link_list    => 1, 
      url_content_md5_hex       => 1, 
      url_script_src_list       => 1, 
      url_scripts_inline_amount => 1, 
      url_scripts_inline_length => 1, 
      url_styles_scr_list       => 1, 
      url_styles_inline_amount  => 1, 
      url_styles_inline_length  => 1, 
      url_img_list              => 1, 
      url_img_alt_text          => 1, 
      url_h1_amount             => 1, 
      url_h1_text               => 1, 
      url_h2_h6_amount          => 1, 
      url_h2_h6_text            => 1, 
      url_bold_strong_amount    => 1, 
      url_bold_strong_text      => 1, 
      url_italic_em_amount      => 1, 
      url_italic_em_text        => 1
   );
   
   ## Check fields
   if (exists $arg->{'fields'})
   {
      for my $f (@{$arg->{'fields'}})
      {
         my $f2 = $f; 
         $f2 =~ s/(url[^\s=]+).*/$1/;
         unless ($fields_db{"$f2"})
         {
            $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on field|'.$f2.' does not exists');
            return 0;      
         }
      }
   }
   
   ## Check fields and values
   if (exists $arg->{'fields'} && (ref $arg->{'fields'}) =~ /array/i &&
       exists $arg->{'values'} && (ref $arg->{'values'}) =~ /array/i &&
       scalar(@{$arg->{'fields'}}) != scalar(@{$arg->{'values'}}))
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on field and value, check them');
      return 0;      
   }
   
   ## Building query
   $sql   =   'SELECT url_id, ';
   $sql  .=          'url_processed, ';
   $sql  .=          'url_url_text_md5_hex, ';
   $sql  .=          'url_url_text, ';
   $sql  .=          'url_inlink_canonical_list, ';
   $sql  .=          'url_canonical_list, ';
   $sql  .=          'url_inlink_list, ';
   $sql  .=          'url_inlink_anchor_text, ';
   $sql  .=          'url_title_list, ';
   $sql  .=          'url_description_list, ';
   $sql  .=          'url_internal_link_list, ';
   $sql  .=          'url_external_link_list, ';
   $sql  .=          'url_content_md5_hex, ';
   $sql  .=          'url_script_src_list, ';
   $sql  .=          'url_scripts_inline_amount, ';
   $sql  .=          'url_scripts_inline_length, ';
   $sql  .=          'url_styles_scr_list, ';
   $sql  .=          'url_styles_inline_amount, ';
   $sql  .=          'url_styles_inline_length, ';
   $sql  .=          'url_img_list, ';
   $sql  .=          'url_img_alt_text, ';
   $sql  .=          'url_h1_amount, ';
   $sql  .=          'url_h1_text, ';
   $sql  .=          'url_h2_h6_amount, ';
   $sql  .=          'url_h2_h6_text, ';
   $sql  .=          'url_bold_strong_amount, ';
   $sql  .=          'url_bold_strong_text, ';
   $sql  .=          'url_italic_em_amount, ';
   $sql  .=          'url_italic_em_text, ';
   $sql  .=          'url_updated ';
   $sql  .=     'FROM urls ';
   $sql  .=    'WHERE '. join(" AND ", @{$arg->{'fields'}}) if (exists $arg->{'fields'} && (ref $arg->{'fields'}) =~ /array/i);
   $sth   = $self->{'dbh'}->prepare($sql);
   @param = (@{$arg->{'values'}})                           if (exists $arg->{'values'} && (ref $arg->{'values'}) =~ /array/i);
   
   ## Running query
   unless($sth->execute(@param))
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;       
   }
   
   delete($arg->{'data'});
   $arg->{'rows'} = $sth->rows;
   
   ## Recovering urls
   foreach my $i (0..($sth->rows)-1)
   {
      my $r = $sth->fetchrow_hashref;
      map {utf8::encode($r->{$_})} keys %{$r};
      
      push @{$arg->{'data'}}, $r;
   }

   $sth->finish;

   return 1;
}


sub insert_url
{
   my($self, $arg) = @_;
   my($sql, $sth, %fields_db, @param);
   
   %fields_db = (
      url_processed             => 1, 
      url_url_text_md5_hex      => 1, 
      url_url_text              => 1, 
      url_inlink_canonical_list => 1, 
      url_canonical_list        => 1, 
      url_inlink_list          => 1, 
      url_inlink_anchor_text    => 1, 
      url_title_list            => 1, 
      url_description_list      => 1, 
      url_internal_link_list    => 1, 
      url_external_link_list    => 1, 
      url_content_md5_hex       => 1, 
      url_script_src_list       => 1, 
      url_scripts_inline_amount => 1, 
      url_scripts_inline_length => 1, 
      url_styles_scr_list       => 1, 
      url_styles_inline_amount  => 1, 
      url_styles_inline_length  => 1, 
      url_img_list              => 1, 
      url_img_alt_text          => 1, 
      url_h1_amount             => 1, 
      url_h1_text               => 1, 
      url_h2_h6_amount          => 1, 
      url_h2_h6_text            => 1, 
      url_bold_strong_amount    => 1, 
      url_bold_strong_text      => 1, 
      url_italic_em_amount      => 1, 
      url_italic_em_text        => 1
   );
   
   ## Check fields
   if (exists $arg->{'fields'})
   {
      for my $f (@{$arg->{'fields'}})
      {
         unless ($fields_db{"$f"})
         {
            $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on field|'.$f.' does not exists');
            return 0;      
         }
      }
   }
   
   ## Check fields and values
   if (exists $arg->{'fields'} && (ref $arg->{'fields'}) =~ /array/i &&
       exists $arg->{'values'} && (ref $arg->{'values'}) =~ /array/i &&
       scalar(@{$arg->{'fields'}}) != scalar(@{$arg->{'values'}}))
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on field and value, check them');
      return 0;      
   }
   
   $sql   = 'INSERT INTO urls ';
   $sql  .=                 ' ('.join(",", @{$arg->{'fields'}}).') ';
   $sql  .=      'VALUES ';
   $sql  .=                 ' ('.join(",", split(//, "?" x scalar @{$arg->{'fields'}})).') ';
   @param = (@{$arg->{'values'}});
   map {utf8::decode($_)} @param;

   unless($self->{'STATS'} = $self->{'dbh'}->do($sql, undef, @param))
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;      
   }
   
   if ($self->{'STATS'} eq '0E0')
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on insert url|'.$sql.'|'."@param");
      return 0;      
   }
   
   $arg->{'url_id'} = $self->{'dbh'}->{'mysql_insertid'};
   
   return 1;
}


sub update_url_id
{
   my($self, $arg) = @_;
   my($sql, $sth, %fields_db, @param);
   
   %fields_db = (
      url_processed             => 1, 
      url_url_text_md5_hex      => 1, 
      url_url_text              => 1, 
      url_inlink_canonical_list => 1, 
      url_canonical_list        => 1, 
      url_inlink_list          => 1, 
      url_inlink_anchor_text    => 1, 
      url_title_list            => 1, 
      url_description_list      => 1, 
      url_internal_link_list    => 1, 
      url_external_link_list    => 1, 
      url_content_md5_hex       => 1, 
      url_script_src_list       => 1, 
      url_scripts_inline_amount => 1, 
      url_scripts_inline_length => 1, 
      url_styles_scr_list       => 1, 
      url_styles_inline_amount  => 1, 
      url_styles_inline_length  => 1, 
      url_img_list              => 1, 
      url_img_alt_text          => 1, 
      url_h1_amount             => 1, 
      url_h1_text               => 1, 
      url_h2_h6_amount          => 1, 
      url_h2_h6_text            => 1, 
      url_bold_strong_amount    => 1, 
      url_bold_strong_text      => 1, 
      url_italic_em_amount      => 1, 
      url_italic_em_text        => 1
   );
   
   ## Check fields
   if (exists $arg->{'fields'})
   {
      for my $f (@{$arg->{'fields'}})
      {
         unless ($fields_db{"$f"})
         {
            $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on field|'.$f.' does not exists');
            return 0;      
         }
      }
   }
   
   ## Check fields and values
   if (exists $arg->{'fields'} && (ref $arg->{'fields'}) =~ /array/i &&
       exists $arg->{'values'} && (ref $arg->{'values'}) =~ /array/i &&
       scalar(@{$arg->{'fields'}}) != scalar(@{$arg->{'values'}})-1)
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on field and value, check them|'.Dumper($arg->{'fields'}).Dumper($arg->{'values'}));
      return 0;      
   }
   
   $sql   = 'UPDATE urls set ';
   $sql  .=                 join(" = ?, ", @{$arg->{'fields'}}).' = ? ';
   $sql  .=  'WHERE url_id = ?';
   @param = (@{$arg->{'values'}}, $arg->{'url_id'});
   map {utf8::decode($_)} @param;

   unless($self->{'STATS'} = $self->{'dbh'}->do($sql, undef, @param))
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;      
   }
   
   if ($self->{'STATS'} eq '0E0')
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on update url|'.$sql.'|'."@param");
      return 0;      
   }
   
   return 1;
}


sub load_titles
{
   my($self, $arg) = @_;
   my($sql, $sth, %fields_db, @param);
   
   %fields_db = (
      tit_id            => 1, 
      tit_title_md5_hex => 1, 
      tit_title         => 1, 
      tit_updated       => 1
   );
   
   ## Check fields
   if (exists $arg->{'fields'})
   {
      for my $f (@{$arg->{'fields'}})
      {
         my $f2 = $f; 
         $f2 =~ s/(url[^\s=]+).*/$1/;
         unless ($fields_db{"$f2"})
         {
            $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on field|'.$f2.' does not exists');
            return 0;      
         }
      }
   }
   
   ## Check fields and values
   if (exists $arg->{'fields'} && (ref $arg->{'fields'}) =~ /array/i &&
       exists $arg->{'values'} && (ref $arg->{'values'}) =~ /array/i &&
       scalar(@{$arg->{'fields'}}) != scalar(@{$arg->{'values'}}))
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on field and value, check them');
      return 0;      
   }
   
   ## Building query
   $sql   =   'SELECT tit_id, ';
   $sql  .=          'tit_title, ';
   $sql  .=          'tit_updated ';
   $sql  .=     'FROM titles ';
   $sql  .=    'WHERE '. join(" AND ", @{$arg->{'fields'}}) if (exists $arg->{'fields'} && (ref $arg->{'fields'}) =~ /array/i);
   $sth   = $self->{'dbh'}->prepare($sql);
   @param = (@{$arg->{'values'}})                           if (exists $arg->{'fields'} && (ref $arg->{'values'}) =~ /array/i);

   ## Running query
   unless($sth->execute(@param))
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;       
   }
   
   delete($arg->{'data'});
   $arg->{'rows'} = $sth->rows;
   
   ## Recovering urls
   foreach my $i (0..($sth->rows)-1)
   {
      my $r = $sth->fetchrow_hashref;
      map {utf8::encode($r->{$_})} keys %{$r};
      
      push @{$arg->{'data'}}, $r;
   }

   $sth->finish;

   return 1;
}


sub insert_title
{
   my($self, $arg) = @_;
   my($sql, $sth, %fields_db, @param);
   
   %fields_db = (
      tit_id            => 1, 
      tit_title_md5_hex => 1, 
      tit_title         => 1, 
      tit_updated       => 1
   );
   
   ## Check fields
   if (exists $arg->{'fields'})
   {
      for my $f (@{$arg->{'fields'}})
      {
         unless ($fields_db{"$f"})
         {
            $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on field|'.$f.' does not exists');
            return 0;      
         }
      }
   }
   
   ## Check fields and values
   if (exists $arg->{'fields'} && (ref $arg->{'fields'}) =~ /array/i &&
       exists $arg->{'values'} && (ref $arg->{'values'}) =~ /array/i &&
       scalar(@{$arg->{'fields'}}) != scalar(@{$arg->{'values'}}))
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on field and value, check them');
      return 0;      
   }
   
   $sql   = 'INSERT INTO titles ';
   $sql  .=                 ' ('.join(",", @{$arg->{'fields'}}).') ';
   $sql  .=      'VALUES ';
   $sql  .=                 ' ('.join(",", split(//, "?" x scalar @{$arg->{'fields'}})).') ';
   @param = (@{$arg->{'values'}});
   map {utf8::decode($_)} @param;

   unless($self->{'STATS'} = $self->{'dbh'}->do($sql, undef, @param))
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;      
   }
   
   if ($self->{'STATS'} eq '0E0')
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on insert title|'.$sql.'|'."@param");
      return 0;      
   }
   
   $arg->{'tit_id'} = $self->{'dbh'}->{'mysql_insertid'};
   
   return 1;
}


sub update_title_id
{
   my($self, $arg) = @_;
   my($sql, $sth, %fields_db, @param);
   
   %fields_db = (
      tit_id            => 1, 
      tit_title_md5_hex => 1, 
      tit_title         => 1, 
      tit_updated       => 1
   );
   
   ## Check fields
   if (exists $arg->{'fields'})
   {
      for my $f (@{$arg->{'fields'}})
      {
         unless ($fields_db{"$f"})
         {
            $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on field|'.$f.' does not exists');
            return 0;      
         }
      }
   }
   
   ## Check fields and values
   if (exists $arg->{'fields'} && (ref $arg->{'fields'}) =~ /array/i &&
       exists $arg->{'values'} && (ref $arg->{'values'}) =~ /array/i &&
       scalar(@{$arg->{'fields'}}) != scalar(@{$arg->{'values'}}))
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on field and value, check them');
      return 0;      
   }
   
   $sql   = 'UPDATE urls set ';
   $sql  .=                 join(" = ?, ", @{$arg->{'fields'}}).' = ? ';
   $sql  .=  'WHERE url_id = ?';
   @param = (@{$arg->{'values'}}, $arg->{'url_id'});
   map {utf8::decode($_)} @param;

   unless($self->{'STATS'} = $self->{'dbh'}->do($sql, undef, @param))
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;      
   }
   
   if ($self->{'STATS'} eq '0E0')
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on update url|'.$sql.'|'."@param");
      return 0;      
   }
   
   return 1;
}


sub load_descriptions
{
   my($self, $arg) = @_;
   my($sql, $sth, %fields_db, @param);
   
   %fields_db = (
      desc_id                  => 1,
      desc_description_md5_hex => 1,
      desc_description         => 1,
      desc_updated             => 1
   );
   
   ## Check fields
   if (exists $arg->{'fields'})
   {
      for my $f (@{$arg->{'fields'}})
      {
         my $f2 = $f; 
         $f2 =~ s/(url[^\s=]+).*/$1/;
         unless ($fields_db{"$f2"})
         {
            $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on field|'.$f2.' does not exists');
            return 0;      
         }
      }
   }
   
   ## Check fields and values
   if (exists $arg->{'fields'} && (ref $arg->{'fields'}) =~ /array/i &&
       exists $arg->{'values'} && (ref $arg->{'values'}) =~ /array/i &&
       scalar(@{$arg->{'fields'}}) != scalar(@{$arg->{'values'}}))
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on field and value, check them');
      return 0;      
   }
   
   ## Building query
   $sql   =   'SELECT desc_id, ';
   $sql  .=          'desc_description_md5_hex, ';
   $sql  .=          'desc_description, ';
   $sql  .=          'desc_updated ';
   $sql  .=     'FROM descriptions ';
   $sql  .=    'WHERE '. join(" AND ", @{$arg->{'fields'}}) if (exists $arg->{'fields'} && (ref $arg->{'fields'}) =~ /array/i);
   $sth   = $self->{'dbh'}->prepare($sql);
   @param = (@{$arg->{'values'}})                           if (exists $arg->{'values'} && (ref $arg->{'values'}) =~ /array/i);
   
   ## Running query
   unless($sth->execute(@param))
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;       
   }
   
   delete($arg->{'data'});
   $arg->{'rows'} = $sth->rows;
   
   ## Recovering urls
   foreach my $i (0..($sth->rows)-1)
   {
      my $r = $sth->fetchrow_hashref;
      map {utf8::encode($r->{$_})} keys %{$r};
      
      push @{$arg->{'data'}}, $r;
   }

   $sth->finish;

   return 1;
}


sub insert_description
{
   my($self, $arg) = @_;
   my($sql, $sth, %fields_db, @param);
   
   %fields_db = (
      desc_id                  => 1,
      desc_description_md5_hex => 1,
      desc_description         => 1,
      desc_updated             => 1
   );
   
   ## Check fields
   if (exists $arg->{'fields'})
   {
      for my $f (@{$arg->{'fields'}})
      {
         unless ($fields_db{"$f"})
         {
            $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on field|'.$f.' does not exists');
            return 0;      
         }
      }
   }
   
   ## Check fields and values
   if (exists $arg->{'fields'} && (ref $arg->{'fields'}) =~ /array/i &&
       exists $arg->{'values'} && (ref $arg->{'values'}) =~ /array/i &&
       scalar(@{$arg->{'fields'}}) != scalar(@{$arg->{'values'}}))
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on field and value, check them');
      return 0;      
   }
   
   $sql   = 'INSERT INTO descriptions ';
   $sql  .=                 ' ('.join(",", @{$arg->{'fields'}}).') ';
   $sql  .=      'VALUES ';
   $sql  .=                 ' ('.join(",", split(//, "?" x scalar @{$arg->{'fields'}})).') ';
   @param = (@{$arg->{'values'}});
   map {utf8::decode($_)} @param;

   unless($self->{'STATS'} = $self->{'dbh'}->do($sql, undef, @param))
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;      
   }
   
   if ($self->{'STATS'} eq '0E0')
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on insert description|'.$sql.'|'."@param");
      return 0;      
   }
   
   $arg->{'desc_id'} = $self->{'dbh'}->{'mysql_insertid'};
   
   return 1;
}


sub load_contents
{
   my($self, $arg) = @_;
   my($sql, $sth, %fields_db, @param);
   
   %fields_db = (
      cont_id              => 1,
      cont_content_md5_hex => 1,
      cont_updated         => 1
   );
   
   ## Check fields
   if (exists $arg->{'fields'})
   {
      for my $f (@{$arg->{'fields'}})
      {
         my $f2 = $f; 
         $f2 =~ s/(url[^\s=]+).*/$1/;
         unless ($fields_db{"$f2"})
         {
            $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on field|'.$f2.' does not exists');
            return 0;      
         }
      }
   }
   
   ## Check fields and values
   if (exists $arg->{'fields'} && (ref $arg->{'fields'}) =~ /array/i &&
       exists $arg->{'values'} && (ref $arg->{'values'}) =~ /array/i &&
       scalar(@{$arg->{'fields'}}) != scalar(@{$arg->{'values'}}))
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on field and value, check them');
      return 0;      
   }
   
   ## Building query
   $sql   =   'SELECT cont_id, ';
   $sql  .=          'cont_content_md5_hex, ';
   $sql  .=          'cont_updated ';
   $sql  .=     'FROM contents ';
   $sql  .=    'WHERE '. join(" AND ", @{$arg->{'fields'}}) if (exists $arg->{'fields'} && (ref $arg->{'fields'}) =~ /array/i);
   $sth   = $self->{'dbh'}->prepare($sql);
   @param = (@{$arg->{'values'}})                           if (exists $arg->{'values'} && (ref $arg->{'values'}) =~ /array/i);
   
   ## Running query
   unless($sth->execute(@param))
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;       
   }
   
   delete($arg->{'data'});
   $arg->{'rows'} = $sth->rows;
   
   ## Recovering urls
   foreach my $i (0..($sth->rows)-1)
   {
      my $r = $sth->fetchrow_hashref;
      map {utf8::encode($r->{$_})} keys %{$r};
      
      push @{$arg->{'data'}}, $r;
   }

   $sth->finish;

   return 1;
}


sub insert_content
{
   my($self, $arg) = @_;
   my($sql, $sth, %fields_db, @param);
   
   %fields_db = (
      cont_id              => 1,
      cont_content_md5_hex => 1,
      cont_updated         => 1
   );
   
   ## Check fields
   if (exists $arg->{'fields'})
   {
      for my $f (@{$arg->{'fields'}})
      {
         unless ($fields_db{"$f"})
         {
            $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on field|'.$f.' does not exists');
            return 0;      
         }
      }
   }
   
   ## Check fields and values
   if (exists $arg->{'fields'} && (ref $arg->{'fields'}) =~ /array/i &&
       exists $arg->{'values'} && (ref $arg->{'values'}) =~ /array/i &&
       scalar(@{$arg->{'fields'}}) != scalar(@{$arg->{'values'}}))
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on field and value, check them');
      return 0;      
   }
   
   $sql   = 'INSERT INTO contents ';
   $sql  .=                 ' ('.join(",", @{$arg->{'fields'}}).') ';
   $sql  .=      'VALUES ';
   $sql  .=                 ' ('.join(",", split(//, "?" x scalar @{$arg->{'fields'}})).') ';
   @param = (@{$arg->{'values'}});
   map {utf8::decode($_)} @param;

   unless($self->{'STATS'} = $self->{'dbh'}->do($sql, undef, @param))
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;      
   }
   
   if ($self->{'STATS'} eq '0E0')
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on insert content|'.$sql.'|'."@param");
      return 0;      
   }
   
   $arg->{'cont_id'} = $self->{'dbh'}->{'mysql_insertid'};
   
   return 1;
}


sub load_scripts
{
   my($self, $arg) = @_;
   my($sql, $sth, %fields_db, @param);
   
   %fields_db = (
      scp_id                 => 1,
      scp_script_src_md5_hex => 1,
      scp_script_src         => 1,
      scp_updated            => 1
   );
   
   ## Check fields
   if (exists $arg->{'fields'})
   {
      for my $f (@{$arg->{'fields'}})
      {
         my $f2 = $f; 
         $f2 =~ s/(url[^\s=]+).*/$1/;
         unless ($fields_db{"$f2"})
         {
            $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on field|'.$f2.' does not exists');
            return 0;      
         }
      }
   }
   
   ## Check fields and values
   if (exists $arg->{'fields'} && (ref $arg->{'fields'}) =~ /array/i &&
       exists $arg->{'values'} && (ref $arg->{'values'}) =~ /array/i &&
       scalar(@{$arg->{'fields'}}) != scalar(@{$arg->{'values'}}))
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on field and value, check them');
      return 0;      
   }
   
   ## Building query
   $sql   =   'SELECT scp_id, ';
   $sql  .=          'scp_script_src_md5_hex, ';
   $sql  .=          'scp_script_src, ';
   $sql  .=          'scp_updated ';
   $sql  .=     'FROM scripts ';
   $sql  .=    'WHERE '. join(" AND ", @{$arg->{'fields'}}) if (exists $arg->{'fields'} && (ref $arg->{'fields'}) =~ /array/i);
   $sth   = $self->{'dbh'}->prepare($sql);
   @param = (@{$arg->{'values'}})                           if (exists $arg->{'values'} && (ref $arg->{'values'}) =~ /array/i);
   
   ## Running query
   unless($sth->execute(@param))
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;       
   }
   
   delete($arg->{'data'});
   $arg->{'rows'} = $sth->rows;
   
   ## Recovering urls
   foreach my $i (0..($sth->rows)-1)
   {
      my $r = $sth->fetchrow_hashref;
      map {utf8::encode($r->{$_})} keys %{$r};
      
      push @{$arg->{'data'}}, $r;
   }

   $sth->finish;

   return 1;
}


sub insert_script
{
   my($self, $arg) = @_;
   my($sql, $sth, %fields_db, @param);
   
   %fields_db = (
      scp_id                 => 1,
      scp_script_src_md5_hex => 1,
      scp_script_src         => 1
   );
   
   ## Check fields
   if (exists $arg->{'fields'})
   {
      for my $f (@{$arg->{'fields'}})
      {
         unless ($fields_db{"$f"})
         {
            $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on field|'.$f.' does not exists');
            return 0;      
         }
      }
   }
   
   ## Check fields and values
   if (exists $arg->{'fields'} && (ref $arg->{'fields'}) =~ /array/i &&
       exists $arg->{'values'} && (ref $arg->{'values'}) =~ /array/i &&
       scalar(@{$arg->{'fields'}}) != scalar(@{$arg->{'values'}}))
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on field and value, check them');
      return 0;      
   }
   
   $sql   = 'INSERT INTO scripts ';
   $sql  .=                 ' ('.join(",", @{$arg->{'fields'}}).') ';
   $sql  .=      'VALUES ';
   $sql  .=                 ' ('.join(",", split(//, "?" x scalar @{$arg->{'fields'}})).') ';
   @param = (@{$arg->{'values'}});
   map {utf8::decode($_)} @param;

   unless($self->{'STATS'} = $self->{'dbh'}->do($sql, undef, @param))
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;      
   }
   
   if ($self->{'STATS'} eq '0E0')
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on insert script|'.$sql.'|'."@param");
      return 0;      
   }
   
   $arg->{'cont_id'} = $self->{'dbh'}->{'mysql_insertid'};
   
   return 1;
}


sub add_inlink_canonical
{
   my($self, $arg) = @_;
   my($sql, $sth, %fields_db, @param);
   
   
   ## Check fields and values
   if (scalar(@{$arg->{'values'}}) < 2)
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on field and value, check them');
      return 0;      
   }
   
   $sql   = 'UPDATE urls ';
   $sql  .=    'SET url_inlink_canonical_list = CONCAT_WS(":", url_inlink_canonical_list, "'.$arg->{'values'}->[0].'") ';
   $sql  .=  'WHERE url_id = ?';
   @param = ($arg->{'values'}->[1]);

   unless($self->{'STATS'} = $self->{'dbh'}->do($sql, undef, @param))
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;      
   }

   if ($self->{'STATS'} eq '0E0')
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on update inlink|'.$sql.'|'."@param");
      return 0;      
   }
   
   return 1;
}


sub add_inlink
{
   my($self, $arg) = @_;
   my($sql, $sth, %fields_db, @param);
   
   
   ## Check fields and values
   if (scalar(@{$arg->{'values'}}) < 2)
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on field and value, check them');
      return 0;      
   }
   
   $sql   = 'UPDATE urls ';
   $sql  .=    'SET url_inlink_list = CONCAT_WS(":", url_inlink_list, ?) ';
   $sql  .=  'WHERE url_id = ?';
   @param = (@{$arg->{'values'}});

   unless($self->{'STATS'} = $self->{'dbh'}->do($sql, undef, @param))
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;      
   }

   if ($self->{'STATS'} eq '0E0')
   {
      $self->{'ERROR'} = set_error(__PACKAGE__, __LINE__, 'error on update inlink|'.$sql.'|'."@param");
      return 0;      
   }
   
   return 1;
}


1;

__END__
