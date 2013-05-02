package MUSTdoSEO::DB::Access;


use strict;
use MUSTdoSEO::DB;
use MUSTdoSEO::Functions qw(set_erro);
use vars qw(@ISA);
@ISA = qw(MUSTdoSEO::DB);

our $VERSION = sprintf "%d.%d", q$Revision: 1.1 $ =~ /(\d+)/g;



sub select_users
{
   my($self, $arg) = @_;
   my($sql, $sth, @param);
   
   ## Montando a query
   $sql  =   'SELECT usu_id, ';
   $sql .=          'usu_login, ';
   $sql .=          'usu_pass, ';
   $sql .=          'usu_name, ';
   $sql .=          'usu_email, ';
   $sql .=          'usu_active, ';
   $sql .=          'usu_registered, ';
   $sql .=          'usu_updated ';
   $sql .=     'FROM users ';
   $sql .=    'WHERE usu_id = ? '    if ($arg->{'usu_id'});
   $sql .=    'WHERE usu_login = ? ' if ($arg->{'usu_login'});
   $sql .= 'ORDER BY usu_name';
   $sth  = $self->{'dbh'}->prepare($sql);
   @param= ($arg->{'usu_id'})    if ($arg->{'usu_id'});
   @param= ($arg->{'usu_login'}) if ($arg->{'usu_login'});
   
   ## Executando Query
   unless($sth->execute(@param))
   {
      $self->{'ERROR'} = set_erro(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;       
   }
   
   delete($arg->{'data'});
   
   ## Recuperando users
   foreach my $i (0..($sth->rows)-1)
   {
      my $r = $sth->fetchrow_hashref;
      map {utf8::encode($r->{$_})} keys %{$r};
      push @{$arg->{'data'}->{'reg'}}, $r;
      $arg->{'data'}->{'user_id'}->{$r->{'usu_id'}}       = $arg->{'data'}->{'reg'}[$i]; ## HASH
      $arg->{'data'}->{'users_login'}->{$r->{'usu_login'}} = $arg->{'data'}->{'reg'}[$i]; ## HASH
   }

   $sth->finish;
   
   my $data = $arg->{'data'}; ## HASH

   if ($data)
   {
      ## Carrega todos os groups de users
      $self->select_groups($arg)
      or do
      {
         $arg->{'ERROR'} = &set_erro(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
         return 0; 
      };

      $data->{'groups'} = $arg->{'data'}->{'reg'}; ## ARRAY

      foreach my $usu_id (keys %{$data->{'user_id'}})
      {
         $data->{'user_id'}->{"$usu_id"}->{'grp_hierarchy'} = $arg->{'data'}->{'rel_usu_id'}->{"$usu_id"};
      }
   }
   
   $arg->{'data'} = $data;

   return 1;
}


sub insert_user
{
   my($self, $arg) = @_;
   my($sql, $sth, @field, @param);
   
   $sql   = 'INSERT INTO users ';
   $sql  .=           '( usu_name, ';
   $sql  .=             'usu_email, ';
   $sql  .=             'usu_login, ';
   $sql  .=             'usu_pass, ';
   $sql  .=             'usu_registered) ';
   $sql  .=      'VALUES (?,?,?,?,now())';
   @param = ($arg->{'usu_name'}, $arg->{'usu_email'}, $arg->{'usu_login'}, $arg->{'usu_pass'});
   map {utf8::decode($_)} @param;

   unless($self->{'STATS'} = $self->{'dbh'}->do($sql, undef, @param))
   {
      $self->{'ERROR'} = set_erro(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;      
   }
   
   if ($self->{'STATS'} eq '0E0')
   {
      $self->{'ERROR'} = set_erro(__PACKAGE__, __LINE__, 'error on insert user|'.$sql.'|'."@param");
      return 0;      
   }
   
   $arg->{'usu_id'} = $self->{'dbh'}->{'mysql_insertid'};
   
   return 1;
}


sub update_user
{
   my($self, $arg) = @_;
   my($sql, $sth, @field, @param);

   if ($arg->{'usu_pass'}) { push @field, 'usu_pass = ?'; push @param, $arg->{'usu_pass'}; }
   if ($arg->{'usu_login'}) { push @field, 'usu_login = ?'; push @param, $arg->{'usu_login'}; }
   if ($arg->{'usu_name'} ) { push @field, 'usu_name = ?';  push @param, $arg->{'usu_name'};  }
   if ($arg->{'usu_email'}) { push @field, 'usu_email = ?'; push @param, $arg->{'usu_email'}; }

   $sql   = 'UPDATE users ';
   $sql  .=    'SET '.join(", ", @field);
   $sql  .= ' WHERE usu_id = ? ';
   push @param, $arg->{'usu_id'};
   map {utf8::decode($_)} @param;

   unless($self->{'STATS'} = $self->{'dbh'}->do($sql, undef, @param))
   {
      $self->{'ERROR'} = set_erro(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;      
   }
   
   if ($self->{'STATS'} eq '0E0')
   {
      $self->{'ERROR'} = set_erro(__PACKAGE__, __LINE__, 'no user found|'.$sql.'|'."@param");
      return 0;      
   }
   
   return 1;
}


sub delete_user
{
   my($self, $arg) = @_;
   my($sql, $sth, @field, @param);
   
   $sql   = 'DELETE FROM rel_users_groups ';
   $sql  .=      ' WHERE usu_id = ? ';
   @param = ($arg->{'usu_id'});

   unless($self->{'STATS'} = $self->{'dbh'}->do($sql, undef, @param))
   {
      $self->{'ERROR'} = set_erro(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;      
   }
   
   $sql   = 'DELETE FROM users ';
   $sql  .=      ' WHERE usu_id = ? ';
   @param = ($arg->{'usu_id'});

   unless($self->{'STATS'} = $self->{'dbh'}->do($sql, undef, @param))
   {
      $self->{'ERROR'} = set_erro(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;      
   }
   
   return 1;
}


sub select_groups
{
   my($self, $arg) = @_;
   my($sql, $sth, @param);
   
   ## Montando a query
   $sql  =   'SELECT grp_id, ';
   $sql .=          'grp_name, ';
   $sql .=          'grp_desc, ';
   $sql .=          'grp_hierarchy, ';
   $sql .=          'grp_registered, ';
   $sql .=          'grp_updated ';
   $sql .=     'FROM groups ';
   $sql .= 'ORDER BY grp_hierarchy ASC ';
   $sth  = $self->{'dbh'}->prepare($sql);
   
   ## Executando Query
   unless($sth->execute(@param))
   {
      $self->{'ERROR'} = set_erro(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;       
   }   
   
   delete($arg->{'data'});

   ## Recuperando groups
   foreach my $i (0..($sth->rows)-1)
   {
      my $r = $sth->fetchrow_hashref;
      map {utf8::encode($r->{$_})} keys %{$r};
      push @{$arg->{'data'}->{'reg'}}, $r;
      $arg->{'data'}->{'groups_id'}->{$r->{'grp_id'}}          = $arg->{'data'}->{'reg'}[$i];
      $arg->{'data'}->{'groups_hrq'}->{$r->{'grp_hierarchy'}} = $arg->{'data'}->{'reg'}[$i];
   }

   ## Recuperando os ids dos groups relacionados ao user
   ## Montando a query
   $sql   =   'SELECT r.usu_id, ';
   $sql  .=          'r.grp_id ';
   $sql  .=     'FROM groups as g, rel_users_groups as r ';
   $sql  .=    'WHERE r.grp_id = g.grp_id ';
   $sql  .=      'AND r.usu_id = ? ' if ($arg->{'usu_id'});
   $sth   = $self->{'dbh'}->prepare($sql);
   @param = ($arg->{'usu_id'}) if ($arg->{'usu_id'});

   ## Executando Query
   unless($sth->execute(@param))
   {
      $self->{'ERROR'} = set_erro(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;       
   }   

   ## Recuperando groups
   foreach (1..$sth->rows)
   {
      my $r = $sth->fetchrow_hashref;

      ##                                |-- usu_id --|    |-------------------- codigo da hierarchy do group----------------|    |------------- registro do group --------------|
      $arg->{'data'}->{'rel_usu_id'}->{$r->{'usu_id'}}->{$arg->{'data'}->{'groups_id'}->{$r->{'grp_id'}}->{'grp_hierarchy'}} = $arg->{'data'}->{'groups_id'}->{$r->{'grp_id'}};

      ##                                |-- grp_id --|    |-- usu_id --|    |------------- registro do group --------------|
      $arg->{'data'}->{'rel_grp_id'}->{$r->{'grp_id'}}->{$r->{'usu_id'}} = $arg->{'data'}->{'groups_id'}->{$r->{'grp_id'}};
   }
   
   $sth->finish;
   return 1;
}


sub insert_group
{
   my($self, $arg) = @_;
   my($sql, $sth, @field, @param);
   
   $sql   = 'INSERT INTO groups ';
   $sql  .=            '(grp_name, ';
   $sql  .=             'grp_desc, ' if ($arg->{'grp_desc'});
   $sql  .=             'grp_hierarchy, ';
   $sql  .=             'grp_registered) ';
   $sql  .=      'VALUES(?,';
   $sql  .=               '?,'       if ($arg->{'grp_desc'});
   $sql  .=                 '?,now()) ';
   push @param, $arg->{'grp_name'};
   push @param, $arg->{'grp_desc'}   if ($arg->{'grp_desc'});
   push @param, $arg->{'grp_hierarchy'};
   map {utf8::decode($_)} @param;
   
   unless($self->{'STATS'} = $self->{'dbh'}->do($sql, undef, @param))
   {
      $self->{'ERROR'} = set_erro(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;      
   }

   if ($self->{'STATS'} eq '0E0')
   {
      $self->{'ERROR'} = set_erro(__PACKAGE__, __LINE__, 'erro ao inserir em groups|'.$sql.'|'."@param");
      return 0;      
   }
   
   return 1;
}


sub update_group
{
   my($self, $arg) = @_;
   my($sql, $sth, @field, @param);
   
   if ($arg->{'grp_name'}       ) { push @field, 'grp_name = ?';        push @param, $arg->{'grp_name'}; }
   if ($arg->{'grp_desc'}       ) { push @field, 'grp_desc = ?';        push @param, $arg->{'grp_desc'}; }
   if ($arg->{'grp_hierarchy'} ) { push @field, 'grp_hierarchy = ?';  push @param, $arg->{'grp_hierarchy'}; }

   $sql   = 'UPDATE groups ';
   $sql  .=    'SET '.join(", ", @field);
   $sql  .= ' WHERE grp_id = ? ';
   push @param, $arg->{'grp_id'};
   map {utf8::decode($_)} @param;

   unless($self->{'STATS'} = $self->{'dbh'}->do($sql, undef, @param))
   {
      $self->{'ERROR'} = set_erro(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;      
   }
   
   if ($self->{'STATS'} eq '0E0')
   {
      $self->{'ERROR'} = set_erro(__PACKAGE__, __LINE__, 'no group found|'.$sql.'|'."@param");
      return 0;      
   }
   
   ##########################################################
   # Faz um acerto na hierarchy dos groups 
   #---------------------------------------------------------
   if ($arg->{'grp_hierarchy'})
   {
      $self->acerta_hierarchy_groups($arg)
      or do
      {
         $arg->{'ERROR'} = &set_erro(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
         return 0; 
      };
   }

   return 1;
}


sub fix_hierarchy_groups
{
   my($self, $arg) = @_;
   my($sql, $sth, @field, @param);

   ##########################################################
   # Faz um acerto na hierarchy dos groups 
   #---------------------------------------------------------
   # Quando um group e tranferido de um hierarchy pra outra 
   # ou sao deletedos, podem ocorrer saltos na numeracao. 
   # O codigo abaixo refaz a hierarchy retirando esses saltos.
   #
   $self->select_groups($arg)
   or do
   {
      $arg->{'ERROR'} = &set_erro(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0; 
   };

   my($len, $len_antigo, $correct_hierarchy, @count);

   foreach my $r (@{$arg->{'data'}->{'reg'}})
   {
      $len = length($r->{'grp_hierarchy'});
      @count = @count[0..$len] if ($len_antigo > $len);
      $len_antigo = $len;
      $count[$len]++;
      $correct_hierarchy = join("", @count[1..$len]);

      ## update caso exista saltos
      if ($r->{'grp_hierarchy'} != $correct_hierarchy)
      {
         $sql   = 'UPDATE groups ';
         $sql  .=    'SET grp_hierarchy = ?';
         $sql  .= ' WHERE grp_id = ? ';
         @param = ($correct_hierarchy, $r->{'grp_id'});

         unless($self->{'STATS'} = $self->{'dbh'}->do($sql, undef, @param))
         {
            $self->{'ERROR'} = set_erro(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
            return 0;      
         }
      }
   }
   
   return 1;
}


sub select_permissions
{
   my($self, $arg) = @_;
   my($sql, $sth, @param);
   
   ## Montando a query
   $sql  =   'SELECT cat_id, ';
   $sql .=          'cat_name, ';
   $sql .=          'cat_desc, ';
   $sql .=          'cat_registered, ';
   $sql .=          'cat_updated ';
   $sql .=     'FROM permissions_categories ';
   $sql .= 'ORDER BY cat_name ASC ';
   $sth  = $self->{'dbh'}->prepare($sql);
   
   ## Executando Query
   unless($sth->execute(@param))
   {
      $self->{'ERROR'} = set_erro(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;       
   }   
   
   delete($arg->{'data'});

   foreach my $i (0..($sth->rows)-1)
   {
      my $r = $sth->fetchrow_hashref;
      map {utf8::encode($r->{$_})} keys %{$r};
      push @{$arg->{'data'}->{'reg'}}, $r;
      $arg->{'data'}->{'categories_id'}->{$r->{'cat_id'}}     = $arg->{'data'}->{'reg'}[$i];
      $arg->{'data'}->{'categories_name'}->{$r->{'cat_name'}} = $arg->{'data'}->{'reg'}[$i];
   }
   
   my %data;
   $data{'categories'} = $arg->{'data'};

   $self->select_groups($arg)
   or do
   {
      $arg->{'ERROR'} = &set_erro(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0; 
   };

   $data{'groups'} = $arg->{'data'};

   ## Montando a query
   $sql   =   'SELECT grp_id, ';
   $sql  .=          'per_id, ';
   $sql  .=          'rel_updated ';
   $sql  .=     'FROM rel_groups_permissions';
   $sth   = $self->{'dbh'}->prepare($sql);

   ## Executando Query
   unless($sth->execute(@param))
   {
      $self->{'ERROR'} = set_erro(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;       
   }   

   delete($arg->{'data'});

   foreach my $i (0..($sth->rows)-1)
   {
      my $r = $sth->fetchrow_hashref;
      map {utf8::encode($r->{$_})} keys %{$r};
      push @{$arg->{'data'}->{'reg'}}, $r;
      $arg->{'data'}->{'rel_per_id'}->{$r->{'per_id'}}->{$r->{'grp_id'}} = $arg->{'data'}->{'reg'}[$i];
      $arg->{'data'}->{'rel_grp_id'}->{$r->{'grp_id'}}->{$r->{'per_id'}} = $arg->{'data'}->{'reg'}[$i];
   }
   
   $data{'rel_per_grp'} = $arg->{'data'};

   ## Montando a query
   $sql   =   'SELECT per_id, ';
   $sql  .=          'cat_id, ';
   $sql  .=          'per_code, ';
   $sql  .=          'per_name, ';
   $sql  .=          'per_desc, ';
   $sql  .=          'per_registered, ';
   $sql  .=          'per_updated ';
   $sql  .=     'FROM permissions';
   $sth   = $self->{'dbh'}->prepare($sql);

   ## Executando Query
   unless($sth->execute(@param))
   {
      $self->{'ERROR'} = set_erro(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;       
   }   

   delete($arg->{'data'});
   $arg->{'data'} = \%data;

   foreach my $i (0..($sth->rows)-1)
   {
      my $r = $sth->fetchrow_hashref;
      map {utf8::encode($r->{$_})} keys %{$r};
      $r->{'groups'} = $arg->{'data'}->{'rel_per_grp'}->{'rel_per_id'}->{$r->{'per_id'}};
      push @{$arg->{'data'}->{'reg'}}, $r;
      $arg->{'data'}->{'permissions_id'}      ->{$r->{'per_id'}}                     = $arg->{'data'}->{'reg'}[$i];
      $arg->{'data'}->{'permissions_code'}    ->{$r->{'per_code'}}                   = $arg->{'data'}->{'reg'}[$i];
      $arg->{'data'}->{'permissions_cat_id'}  ->{$r->{'cat_id'}}  ->{$r->{'per_id'}} = $arg->{'data'}->{'reg'}[$i];
   }
      
   $sth->finish;
   return 1;
}


sub insert_permission
{
   my($self, $arg) = @_;
   my($sql, $sth, @field, @param);
   
   $sql   = 'INSERT INTO permissions ';
   $sql  .=            '(per_code, ';
   $sql  .=             'cat_id, ';
   $sql  .=             'per_name, ';
   $sql  .=             'per_desc, ' if ($arg->{'per_desc'});
   $sql  .=             'per_registered) ';
   $sql  .=      'VALUES(?,?,?,';
   $sql  .=               '?,'       if ($arg->{'per_desc'});
   $sql  .=                 'now()) ';
   push @param, $arg->{'per_code'};
   push @param, $arg->{'cat_id'};
   push @param, $arg->{'per_name'};
   push @param, $arg->{'per_desc'}   if ($arg->{'per_desc'});
   map {utf8::decode($_)} @param;
   
   unless($self->{'STATS'} = $self->{'dbh'}->do($sql, undef, @param))
   {
      $self->{'ERROR'} = set_erro(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;      
   }

   if ($self->{'STATS'} eq '0E0')
   {
      $self->{'ERROR'} = set_erro(__PACKAGE__, __LINE__, 'erro ao inserir em groups|'.$sql.'|'."@param");
      return 0;      
   }
   
   return 1;
}


sub update_permissions
{
   my($self, $arg) = @_;
   my($sql, $sth, @field, @param);
   
   if ($arg->{'per_code'}) { push @field, 'per_code = ?'; push @param, $arg->{'per_code'}; }
   if ($arg->{'per_name'}) { push @field, 'per_name = ?'; push @param, $arg->{'per_name'}; }
   if ($arg->{'cat_id'}  ) { push @field, 'cat_id = ?'; push @param, $arg->{'cat_id'}; }
   if ($arg->{'per_desc'}) { push @field, 'per_desc = ?'; push @param, $arg->{'per_desc'}; }

   $sql   = 'UPDATE permissions ';
   $sql  .=    'SET '.join(", ", @field);
   $sql  .= ' WHERE per_id = ? ';
   push @param, $arg->{'per_id'};
   map {utf8::decode($_)} @param;

   unless($self->{'STATS'} = $self->{'dbh'}->do($sql, undef, @param))
   {
      $self->{'ERROR'} = set_erro(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;      
   }
   
   return 1;
}


sub delete_permission
{
   my($self, $arg) = @_;
   my($sql, $sth, @field, @param);
   
   $sql   = 'DELETE FROM rel_groups_permissions ';
   $sql  .=      ' WHERE per_id = ? ';
   @param = ($arg->{'per_id'});

   unless($self->{'STATS'} = $self->{'dbh'}->do($sql, undef, @param))
   {
      $self->{'ERROR'} = set_erro(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;      
   }
   
   $sql   = 'DELETE FROM permissions ';
   $sql  .=      ' WHERE per_id = ? ';
   @param = ($arg->{'per_id'});

   unless($self->{'STATS'} = $self->{'dbh'}->do($sql, undef, @param))
   {
      $self->{'ERROR'} = set_erro(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;      
   }
   
   return 1;
}


sub encontra_cod_proxima_hierarchy_group
{
   my($self, $arg) = @_;
   my($sql, $sth, @param);
   
   ## Montando a query
   $sql   =   'SELECT max(substring(grp_hierarchy,'.$arg->{'len_hierarchy'}.',1)) as nivel_hierarchy ';
   $sql  .=     'FROM groups ';
   $sql  .=    'WHERE grp_hierarchy like "'.$arg->{'grp_hierarchy'}.'%"';

   $sth   = $self->{'dbh'}->prepare($sql);

   ## Executando Query
   unless($sth->execute(@param))
   {
      $self->{'ERROR'} = set_erro(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;       
   }   
   
   delete($arg->{'data'});

   my $r = $sth->fetchrow_hashref;
   $arg->{'data'} = $r;
   
   $sth->finish;
   return 1;
}


sub insert_category
{
   my($self, $arg) = @_;
   my($sql, $sth, @field, @param);
   
   $sql   = 'INSERT INTO permissions_categories ';
   $sql  .=            '(cat_name, ';
   $sql  .=             'cat_desc, ' if ($arg->{'cat_desc'});
   $sql  .=             'cat_registered) ';
   $sql  .=      'VALUES(?,';
   $sql  .=               '?,'       if ($arg->{'cat_desc'});
   $sql  .=                 'now()) ';
   push @param, $arg->{'cat_name'};
   push @param, $arg->{'cat_desc'}   if ($arg->{'cat_desc'});
   map {utf8::decode($_)} @param;
   
   unless($self->{'STATS'} = $self->{'dbh'}->do($sql, undef, @param))
   {
      $self->{'ERROR'} = set_erro(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;      
   }

   if ($self->{'STATS'} eq '0E0')
   {
      $self->{'ERROR'} = set_erro(__PACKAGE__, __LINE__, 'erro on insert groups|'.$sql.'|'."@param");
      return 0;      
   }
   
   return 1;
}


sub update_categories
{
   my($self, $arg) = @_;
   my($sql, $sth, @field, @param);
   
   if ($arg->{'cat_name'}) { push @field, 'cat_name = ?'; push @param, $arg->{'cat_name'}; }
   if ($arg->{'cat_desc'}) { push @field, 'cat_desc = ?'; push @param, $arg->{'cat_desc'}; }

   $sql   = 'UPDATE permissions_categories ';
   $sql  .=    'SET '.join(", ", @field);
   $sql  .= ' WHERE cat_id = ? ';
   push @param, $arg->{'cat_id'};
   map {utf8::decode($_)} @param;

   unless($self->{'STATS'} = $self->{'dbh'}->do($sql, undef, @param))
   {
      $self->{'ERROR'} = set_erro(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;      
   }
   
   return 1;
}


sub delete_category
{
   my($self, $arg) = @_;
   my($sql, $sth, @field, @param);
   
   $sql   = 'DELETE FROM permissions_categories ';
   $sql  .=      ' WHERE cat_id = ? ';
   @param = ($arg->{'cat_id'});

   unless($self->{'STATS'} = $self->{'dbh'}->do($sql, undef, @param))
   {
      $self->{'ERROR'} = set_erro(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;      
   }
   
   $sql   = 'UPDATE permissions ';
   $sql  .=    'SET cat_id = null';
   $sql  .= ' WHERE cat_id = ? ';
   push @param, $arg->{'cat_id'};

   unless($self->{'STATS'} = $self->{'dbh'}->do($sql, undef, @param))
   {
      $self->{'ERROR'} = set_erro(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;      
   }
   
   return 1;
}


sub update_rel_users_groups
{
   my($self, $arg) = @_;
   my($sql, $sth, @field, @param);
   
   $sql   = 'DELETE FROM rel_users_groups ';
   $sql  .=      ' WHERE usu_id = ? ';
   @param = ($arg->{'usu_id'});

   unless($self->{'STATS'} = $self->{'dbh'}->do($sql, undef, @param))
   {
      $self->{'ERROR'} = set_erro(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;      
   }
   
   $sql   = 'INSERT INTO rel_users_groups ';
   $sql  .=            '(usu_id, ';
   $sql  .=             'grp_id) ';
   $sql  .=      'VALUES(?,?) ';
   
   foreach my $grp_id (keys %{$arg->{'grp_ids'}})
   {
      @param = ($arg->{'usu_id'}, $grp_id);

      unless($self->{'STATS'} = $self->{'dbh'}->do($sql, undef, @param))
      {
         $self->{'ERROR'} = set_erro(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
         return 0;      
      }

#      if ($self->{'STATS'} eq '0E0')
#      {
#         $self->{'ERROR'} = set_erro(__PACKAGE__, __LINE__, 'erro ao inserir em rel_users_groups|'.$sql.'|'."@param");
#         return 0;      
#      }
   }
   
   return 1;
}


sub delete_group
{
   my($self, $arg) = @_;
   my($sql, $sth, @field, @param);
   
   $sql   = 'DELETE FROM rel_users_groups ';
   $sql  .=      ' WHERE grp_id = ? ';
   @param = ($arg->{'grp_id'});

   unless($self->{'STATS'} = $self->{'dbh'}->do($sql, undef, @param))
   {
      $self->{'ERROR'} = set_erro(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;      
   }
   
   $sql   = 'DELETE FROM groups ';
   $sql  .=      ' WHERE grp_id = ? ';
   @param = ($arg->{'grp_id'});

   unless($self->{'STATS'} = $self->{'dbh'}->do($sql, undef, @param))
   {
      $self->{'ERROR'} = set_erro(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;      
   }
   
   ##########################################################
   # Faz um acerto na hierarchy dos groups 
   #---------------------------------------------------------
   $self->acerta_hierarchy_groups($arg)
   or do
   {
      $arg->{'ERROR'} = &set_erro(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0; 
   };

   return 1;
}


sub active_inactive_user
{
   my($self, $arg) = @_;
   my($sql, $sth, @field, @param);
   
   $sql   = 'UPDATE users SET usu_active = usu_active * -1 ';
   $sql  .=  'WHERE usu_id = ? ';
   @param = ($arg->{'usu_id'});

   unless($self->{'STATS'} = $self->{'dbh'}->do($sql, undef, @param))
   {
      $self->{'ERROR'} = set_erro(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;      
   }
   
   ## select user apenas o user modificado
   $self->select_users($arg)
   or do
   {
      $arg->{'ERROR'} = &set_erro(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0; 
   };
      
   return 1;
}


sub update_permissions_group
{
   my($self, $arg) = @_;
   my($sql, $sth, @field, @param);

   ## permissions nao selecionadas
   my $per_ids_n_sel = join(",", split(//, "?" x (scalar(keys %{$arg->{'updater'}->{'per_ids_n_sel'}}))));
   my @per_ids_n_sel =                                  (keys %{$arg->{'updater'}->{'per_ids_n_sel'}});

   ## groups com hieraquia inferior
   my $grp_ids_inf   = join(",", split(//, "?" x (scalar(keys %{$arg->{'updater'}->{'grp_ids_inf'}})+1)));
   my @grp_ids_inf   =                                  (keys %{$arg->{'updater'}->{'grp_ids_inf'}}, $arg->{'grp_id'});

   ## As permissions deselecionadas tambem sao retiradas dos groups com hierarchy inferior
   if ($per_ids_n_sel)
   {
      $sql   = 'DELETE FROM rel_groups_permissions ';
      $sql  .=       'WHERE grp_id in('.$grp_ids_inf.') ';
      $sql  .=         'AND per_id in('.$per_ids_n_sel.') ';
      @param = (@grp_ids_inf, @per_ids_n_sel);
   }
   
   ## Se nao existe nada para deselecionar, entao muda apenas o group em questao
   else
   {
      $sql   = 'DELETE FROM rel_groups_permissions ';
      $sql  .=       'WHERE grp_id in(?) ';
      @param = ($arg->{'grp_id'});
   }

   unless($self->{'STATS'} = $self->{'dbh'}->do($sql, undef, @param))
   {
      $self->{'ERROR'} = set_erro(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;      
   }
   
   ## permissions selecionadas
   my $per_ids_sel   = join(",", split(//, "?" x (scalar(keys %{$arg->{'updater'}->{'per_ids_sel'}}))));
   my @per_ids_sel   =                                  (keys %{$arg->{'updater'}->{'per_ids_sel'}});
   
   ## groups com hierarchy superior
   my $grp_ids_sup   = join(",", split(//, "?" x (scalar(keys %{$arg->{'updater'}->{'grp_ids_sup'}})+1)));
   my @grp_ids_sup   =                                  (keys %{$arg->{'updater'}->{'grp_ids_sup'}}, $arg->{'grp_id'});

   ## As permissions selecionadas sao retiradas, inclusive dos groups com hierarchy superior
   if ($per_ids_sel)
   {
      $sql   = 'DELETE FROM rel_groups_permissions ';
      $sql  .=       'WHERE grp_id in('.$grp_ids_sup.') ';
      $sql  .=         'AND per_id in('.$per_ids_sel.') ';
      @param = (@grp_ids_sup, @per_ids_sel);
   }
   
   ## Se nenhuma permission foi selecionada, entao retira apenas as permissions do group em questao
   else
   {
      $sql   = 'DELETE FROM rel_groups_permissions ';
      $sql  .=       'WHERE grp_id in(?) ';
      @param = ($arg->{'grp_id'});
   }

   unless($self->{'STATS'} = $self->{'dbh'}->do($sql, undef, @param))
   {
      $self->{'ERROR'} = set_erro(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
      return 0;      
   }
   
   ## insert as permissions selecionadas e propaga nas hierarchys superiores
   $sql   = 'INSERT INTO rel_groups_permissions ';
   $sql  .=           '( grp_id, ';
   $sql  .=             'per_id ) ';
   $sql  .=      'VALUES (?,?)';

   foreach my $grp_id (@grp_ids_sup)
   {
      foreach my $per_id (@per_ids_sel)
      {
         @param = ($grp_id, $per_id);

         unless($self->{'STATS'} = $self->{'dbh'}->do($sql, undef, @param))
         {
            $self->{'ERROR'} = set_erro(__PACKAGE__, __LINE__, 'error on query|'.$self->{'dbh'}->errstr.'|'.$sql.'|'."@param");
            return 0;      
         }
      }
   }
   
   return 1;
}



1;

__END__
