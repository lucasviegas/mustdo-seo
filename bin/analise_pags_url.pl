#!/usr/bin/perl

$|=1;

use strict;
#use warnings;
use lib '../lib';
use Data::Dumper;
use MUSTdoSEO::DB::ParserTools;
use MUSTdoSEO::Functions qw(get_date set_error);
use Digest::MD5 qw(md5 md5_hex md5_base64);
use Web::Query2;
use HTML::Entities;
our $VERSION = sprintf "%d.%d", q$Revision: 1.1 $ =~ /(\d+)/g;

use DBI;

#########################################

my ($root_url, $db, %all_urls, %all_titles, %all_descriptions, %all_contents, %all_scripts, %to_parse, %arg, %temp, %aux, %title, %desc, %content, %summarize);

$root_url = 'http://www.walmart.com.br';

$db = new MUSTdoSEO::DB::ParserTools({database => 'mustdo-seo',
                                      hostname => 'localhost:3306',
                                      username => 'root',
                                      password => 'mudar123'});

## Load all Urls on db
unless ($db->load_urls(\%arg))
{
   print &set_error(__FILE__, __LINE__, $db->error).$/;
   exit;
}

if ($arg{'rows'})
{
   foreach my $u (@{$arg{'data'}})
   {
      $all_urls{$u->{'url_url_text'}} = $u->{'url_id'};
   }
}

## Load all Titles on db
unless ($db->load_titles(\%arg))
{
   print &set_error(__FILE__, __LINE__, $db->error).$/;
   exit;
}

if ($arg{'rows'})
{
   foreach my $t (@{$arg{'data'}})
   {
      $all_titles{$t->{'tit_title'}} = $t->{'tit_id'};
   }
}

## Load all Descriptions on db
unless ($db->load_descriptions(\%arg))
{
   print &set_error(__FILE__, __LINE__, $db->error).$/;
   exit;
}

if ($arg{'rows'})
{
   foreach my $d (@{$arg{'data'}})
   {
      $all_descriptions{$d->{'desc_description'}} = $d->{'desc_id'};
   }
}

## Load all Urls on db
unless ($db->load_contents(\%arg))
{
   print &set_error(__FILE__, __LINE__, $db->error).$/;
   exit;
}

if ($arg{'rows'})
{
   foreach my $c (@{$arg{'data'}})
   {
      $all_contents{$c->{'cont_content_md5_hex'}} = $c->{'cont_id'};
   }
}

## Load all Scripts source on db
unless ($db->load_scripts(\%arg))
{
   print &set_error(__FILE__, __LINE__, $db->error).$/;
   exit;
}

if ($arg{'rows'})
{
   foreach my $c (@{$arg{'data'}})
   {
      $all_scripts{$c->{'scp_script_src'}} = $c->{'scp_id'};
   }
}

## Load only Urls to parse
$arg{'root_url'} = $root_url;
unless ($db->load_urls_to_parse(\%arg))
{
   print &set_error(__FILE__, __LINE__, $db->error).$/;
   exit;
}

if ($arg{'rows'})
{
   foreach my $u (@{$arg{'data'}})
   {
      $to_parse{$u->{'url_url_text'}} = $u->{'url_id'};
   }
}
else
{
   $to_parse{"$root_url"} = 1;
}


## Start parser
while (scalar keys %to_parse)
{
   my ($url, $id) = each %to_parse;
   delete $to_parse{"$url"};

   my %aux = ('base' => { 'url_id'           => $id, 
                          'url_text'         => $url, 
                          'root_url'         => $root_url, 
                          'all_urls'         => \%all_urls, 
                          'all_titles'       => \%all_titles, 
                          'all_descriptions' => \%all_descriptions, 
                          'all_contents'     => \%all_contents, 
                          'all_scripts'      => \%all_scripts });

print $id.'|'.$url.$/;

   ## Load HTML
   if (&load_html(\%aux))
   {
      ## Proccess content
      &process_content(\%aux);
      
      ## Put on db
      &put_on_db($db, \%aux);
   }
   else
   {
      print $aux{'error'}.$/;
   }
}

#print Dumper(\%aux);

exit;


sub put_on_db
{
   my($db, $arg) = @_;
   
   my($save);
   
   $save = {'int_links'      => [], 
            'ext_links'      => [], 
            'titles'         => [], 
            'descriptions'   => [], 
            'canonical_list' => [], 
            'scripts'        => [], 
            };

   ## Insert links found in HTML on db
   foreach my $u (@{$arg->{'process_content'}{'int_links'}})
   {
      if (exists $arg->{"base"}->{"all_urls"}{"$u"})
      {
         push @{$save->{'int_links'}}, $arg->{"base"}->{"all_urls"}{"$u"};
         next;
      }

      $arg->{'fields'} = ['url_url_text', 'url_url_text_md5_hex', 'url_processed'];
      $arg->{'values'} = [$u, md5_hex($u), 0];
      $db->insert_url($arg)
      or do
      {
         unless ($db->error =~ /Duplicate entry/i)
         {
            print &set_error(__FILE__, __LINE__, $db->error).$/;
         }
         next;
      };

      $arg->{"base"}->{"all_urls"}{"$u"} = $arg->{'url_id'};

      $arg->{'values'} = [$arg->{"base"}->{"url_id"}, $arg->{"base"}->{"all_urls"}{"$u"}];
      $db->add_inlink($arg)
      or do
      {
         print &set_error(__FILE__, __LINE__, $db->error).$/;
      };

      push @{$save->{'int_links'}}, $arg->{"base"}->{"all_urls"}{"$u"};
   }

   foreach my $u (@{$arg->{'process_content'}{'ext_links'}})
   {
      if (exists $arg->{"base"}->{"all_urls"}{"$u"})
      {
         push @{$save->{'ext_links'}}, $arg->{"base"}->{"all_urls"}{"$u"};
         next;
      }

      $arg->{'fields'} = ['url_url_text', 'url_url_text_md5_hex', 'url_processed'];
      $arg->{'values'} = [$u, md5_hex($u), 0];
      $db->insert_url($arg)
      or do
      {
         unless ($db->error =~ /Duplicate entry/i)
         {
            print &set_error(__FILE__, __LINE__, $db->error).$/;
         }
         next;
      };

      $arg->{"base"}->{"all_urls"}{"$u"} = $arg->{'url_id'};
      push @{$save->{'ext_links'}}, $arg->{"base"}->{"all_urls"}{"$u"};
   }

   ## Insert titles found in HTML on db
   foreach my $t (keys %{$arg->{'process_content'}{'tag_title'}})
   {
      encode_entities ($t, '^\n\x20-\x25\x27-\x7e');
      
      if (exists $arg->{"base"}->{"all_titles"}{"$t"})
      {
         push @{$save->{'titles'}}, $arg->{"base"}->{"all_titles"}{"$t"};
         next;
      }

      $arg->{'fields'} = ['tit_title', 'tit_title_md5_hex'];
      $arg->{'values'} = [$t, md5_hex($t)];
      $db->insert_title($arg)
      or do
      {
         unless ($db->error =~ /Duplicate entry/i)
         {
            print &set_error(__FILE__, __LINE__, $db->error).$/;
         }
         next;
      };

      $arg->{"base"}->{"all_titles"}{"$t"} = $arg->{'tit_id'};
      push @{$save->{'titles'}}, $arg->{"base"}->{"all_titles"}{"$t"};
   }

   ## Insert description found in HTML on db
   foreach my $d (keys %{$arg->{'process_content'}{'meta_description'}})
   {
      encode_entities ($d, '^\n\x20-\x25\x27-\x7e');
      
      if (exists $arg->{"base"}->{"all_descriptions"}{"$d"})
      {
         push @{$save->{'descriptions'}}, $arg->{"base"}->{"all_descriptions"}{"$d"};
         next;
      }

      $arg->{'fields'} = ['desc_description', 'desc_description_md5_hex'];
      $arg->{'values'} = [$d, md5_hex($d)];
      $db->insert_description($arg)
      or do
      {
         unless ($db->error =~ /Duplicate entry/i)
         {
            print &set_error(__FILE__, __LINE__, $db->error).$/;
         }
         next;
      };

      $arg->{"base"}->{"all_descriptions"}{"$d"} = $arg->{'desc_id'};
      push @{$save->{'descriptions'}}, $arg->{"base"}->{"all_descriptions"}{"$d"};
   }

   ## Insert scripts src found in HTML on db
   foreach my $s (keys %{$arg->{'process_content'}{'scripts'}})
   {
      if (exists $arg->{"base"}->{"all_scripts"}{"$s"})
      {
         push @{$save->{'scripts'}}, $arg->{"base"}->{"all_scripts"}{"$s"};
         next;
      }

      $arg->{'fields'} = ['scp_script_src','scp_script_src_md5_hex'];
      $arg->{'values'} = [$s, md5_hex($s)];
      $db->insert_script($arg)
      or do
      {
         unless ($db->error =~ /Duplicate entry/i)
         {
            print &set_error(__FILE__, __LINE__, $db->error).$/;
         }
         next;
      };

      $arg->{"base"}->{"all_scripts"}{"$s"} = $arg->{'scp_id'};
      push @{$save->{'scripts'}}, $arg->{"base"}->{"all_scripts"}{"$s"};
   }

   ## Insert content found in HTML on db
   unless (exists $arg->{"base"}->{"all_contents"}{$arg->{'process_content'}{'content_md5_hex'}})
   {
      $arg->{'fields'} = ['cont_content_md5_hex'];
      $arg->{'values'} = [$arg->{'process_content'}{'content_md5_hex'}];
      $db->insert_content($arg)
      or do
      {
         unless ($db->error =~ /Duplicate entry/i)
         {
            print &set_error(__FILE__, __LINE__, $db->error).$/;
         }
         next;
      };

      $arg->{"base"}->{"all_contents"}{$arg->{'process_content'}{'content_md5_hex'}} = $arg->{'cont_id'};
   }

   ## Insert inlink canonical found in HTML on db
   foreach my $c (keys %{$arg->{'process_content'}{'link_canonical'}})
   {
      unless (exists $arg->{"base"}->{"all_urls"}{"$c"})
      {
         $arg->{'fields'} = ['url_url_text', 'url_url_text_md5_hex', 'url_processed'];
         $arg->{'values'} = [$c, md5_hex($c), 0];
         $db->insert_url($arg)
         or do
         {
            unless ($db->error =~ /Duplicate entry/i)
            {
               print &set_error(__FILE__, __LINE__, $db->error).$/;
            }
            next;
         };

         $arg->{"base"}->{"all_urls"}{"$c"} = $arg->{'url_id'};
      }

      $arg->{'values'} = [$arg->{"base"}->{"url_id"}, $arg->{"base"}->{"all_urls"}{"$c"}];
      $db->add_inlink_canonical($arg)
      or do
      {
         print &set_error(__FILE__, __LINE__, $db->error).$/;
      };

      push @{$save->{'canonical_list'}}, $arg->{"base"}->{"all_urls"}{"$c"};
   }

   ## Check if URL is on db
   if ($arg->{"base"}->{"all_urls"}{$arg->{"base"}->{'url_text'}})
   {
      $arg->{'data'}->[0]->{'url_id'} = $arg->{"base"}->{"all_urls"}{$arg->{"base"}->{'url_text'}};
   }
   else
   {
      $arg->{'fields'} = ['url_url_text = ?'];
      $arg->{'values'} = [$arg->{"base"}->{'url_text'}];
      $db->load_url($arg)
      or do
      {
         print &set_error(__FILE__, __LINE__, $db->error).$/;
         exit;
      };
   }

   $arg->{'fields'} = ['url_url_text_md5_hex',
                       'url_url_text',
                       'url_processed',
                       'url_canonical_list',
                       'url_title_list',
                       'url_description_list',
                       'url_internal_link_list',
                       'url_external_link_list',
                       'url_script_src_list', 
                       'url_scripts_inline_amount', 
                       'url_scripts_inline_length', 
                       'url_content_md5_hex', 
                       'url_response_code', 
                       'url_response_message', 
                       'url_response_header'];
   $arg->{'values'} = [md5_hex($arg->{"base"}->{'url_text'}), 
                       $arg->{"base"}->{'url_text'}, 
                       1, 
                       join(":", @{$save->{'canonical_list'}}), 
                       join(":", @{$save->{'titles'}}), 
                       join(":", @{$save->{'descriptions'}}), 
                       join(":", @{$save->{'int_links'}}), 
                       join(":", @{$save->{'ext_links'}}), 
                       join(":", @{$save->{'scripts'}}), 
                       $arg->{'process_content'}{'scripts_inline_amount'}, 
                       $arg->{'process_content'}{'scripts_inline_length'}, 
                       $arg->{'process_content'}{'content_md5_hex'}, 
                       $arg->{'load_html'}{'code'}, 
                       $arg->{'load_html'}{'message'}, 
                       $arg->{'load_html'}{'header'}];

   ## Update if already on db
   if ($arg->{'data'}->[0]->{'url_id'})
   {
      push @{$arg->{'values'}}, $arg->{'data'}->[0]->{'url_id'};
      $db->update_url_id($arg)
      or do
      {
         print &set_error(__FILE__, __LINE__, $db->error).$/;
         exit;
      };
   }

   ## Insert if not on db yet
   else
   {
      $db->insert_url($arg)
      or do
      {
         print &set_error(__FILE__, __LINE__, $db->error.'|'.$arg->{"base"}->{'url_text'}).$/;
         exit;
      };
   }
}


sub process_content
{
   my($arg) = @_;
   
   my($q, $link, $absolute);
   
   $arg->{'process_content'} = {};
   $q = Web::Query2->new_from_html($arg->{'load_html'}{'html'});

   ## HREF
   $q->find('a')->each(sub
   {
      $link = $absolute = $_[1]->attr('href');

#      my %all_attr;
#
#      foreach my $attr (keys $_[1]->all_attr())
#      {
#         $all_attr{"$attr"} = $_[1]->attr("$attr") if ($atrr !~ /^([^_].*)/);
#      }
#      
#      $all_attr{"$href"} = $link;

      if ($link =~ m#^$arg->{'base'}->{'root_url'}#)
      {
         $absolute  =  $link;
         push @{$arg->{'process_content'}{'int_links'}}, $absolute;
      }
      elsif ($link =~ m{^[/#]} || $link !~ m#^(http|ftp|mail|java)#)
      {
         $absolute  =  $arg->{'base'}->{'root_url'};
         $absolute  =~ s#/+$##;
         $absolute  .= ($link =~ m#^/#) ? $link : '/'.$link;
         push @{$arg->{'process_content'}{'int_links'}}, $absolute;

#      push @{$analyze_dbm{'urls'}}, $absolute unless (grep {$_ =~ m/^\Q$absolute\E$/i} @{$analyze_dbm{'urls'}});
      }
      else
      {
         $absolute  =  $link;
         push @{$arg->{'process_content'}{'ext_links'}}, $absolute;
      }
   });
   
#   my $too_many;
#   $too_many++ if ((ref $arg->{'process_content'}{'ext_links'}) =~ /array/i && scalar(@{$arg->{'process_content'}{'ext_links'}}) > 50);
#   $too_many++ if ((ref $arg->{'process_content'}{'int_links'}) =~ /array/i && scalar(@{$arg->{'process_content'}{'int_links'}}) > 100);
#   $arg->{'process_content'}{'summarize'}{'too_many_links'}++ if ($too_many);

   ## TITLE
   $q->find('title')->each(sub
   {
      my $t = $_[1]->text;
      $arg->{'process_content'}{'tag_title'}{"$t"}++;
   });

   ## DESCRIPTION
   $q->find('meta[name=description]')->each(sub
   {
      my $d=$_[1]->attr('content');
      $arg->{'process_content'}{'meta_description'}{"$d"}++;
   });
   
   ## KEYWORDS
   $q->find('meta[name=keywords]')->each(sub
   {
      my $c=$_[1]->attr('content');
      $arg->{'process_content'}{'meta_keywords'}{"$c"}++;
   });

   ## ROBOTS
   $q->find('meta[name=robots]')->each(sub
   {
      my $r=$_[1]->attr('content');
      $arg->{'process_content'}{'meta_robots'}{"$r"}++;
   });

   ## CANONICAL
   $q->find('link[rel=canonical]')->each(sub
   {
      my $c=$_[1]->attr('href');
      $arg->{'process_content'}{'link_canonical'}{"$c"}++;
   });

   ## SCRIPT
   $q->find('script')->each(sub
   {
      my $s=$_[1]->attr('src');
      
      if ($s)
      {
         $arg->{'process_content'}{'scripts'}{"$s"}++;
      }
      else
      {
         $arg->{'process_content'}{'scripts_inline_amount'}++;
         $arg->{'process_content'}{'scripts_inline_length'} += length($_[1]->html());
      }
   });

   ## CONTENT
   $arg->{'process_content'}{'content_md5_hex'} = md5_hex(encode_entities ($q->html(), '^\n\x20-\x25\x27-\x7e'));
   
   return 1;
}


sub load_html
{
   my($arg) = @_;
   my($ua, $req, $res);

   $arg->{'load_html'} = {};

   require LWP::UserAgent;

   $ua   = new LWP::UserAgent;
   $ua->env_proxy;
   $ua->agent('Mozilla/5.0');
   $ua->timeout(60);
   $req  = HTTP::Request->new(HEAD => $arg->{"base"}->{'url_text'});
   $res  = $ua->request($req);
   $arg->{'load_html'}{'header'} = $res->as_string();
   $arg->{'load_html'}{'type'} = $res->header('content_type');

   if ($arg->{'load_html'}{'type'} =~ /html/i)
   {
      $req = HTTP::Request->new(GET => $arg->{"base"}->{'url_text'});
      $res = $ua->request($req);

      $arg->{'load_html'}{'status'}  = $res->status_line;
      $arg->{'load_html'}{'code'}    = $res->code;
      $arg->{'load_html'}{'message'} = $res->message;
      $arg->{'load_html'}{'html'}    = $res->content;
   }
   else
   {
      $arg->{'load_html'}{'status'}  = $res->status_line;
      $arg->{'load_html'}{'code'}    = $res->code;
      $arg->{'load_html'}{'message'} = $res->message;
   }
   
   return 1;
}


__END__

## Historias

Fazer a análise de uma página HTML identificando as tags e atributos encontrados assim como a ordem e quantidade de ocorrência dos componentes da página. Também recuperar as informações do servidor recebidas no header.

Preciso saber as ocorrências de títulos, descrições e conteúdo redundante.

Preciso saber as canonical existentes e quem está indicando elas. A mesma situação para os links internos, externos, scripts e css.




