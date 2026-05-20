structural_elements = ["structuralObjectClass", "entryUUID", "creatorsName", "createTimestamp", "entryCSN", "modifiersName", "modifyTimestamp"]
with open("/opt/bak/kdc/gigaware.lan.stripped.ldif","w+") as outfile:
   with open("/opt/bak/kdc/gigaware.lan.ldif", "r") as infile:
      lines = infile.readlines()
      for line in lines:
                print line.split(":")[0]
                if line.split(":")[0] in structural_elements:
                    print "ignoring ,", line
                else:
                    outfile.write(line)
